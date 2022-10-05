#! /usr/local/bin/python3

import azure.functions as func
import logging
import requests
import json
import os
import io

from datetime import datetime
from requests.adapters import HTTPAdapter

OBSERVE_CLIENT = None


class ObserveClient:
    def __init__(self):
        # Required environment variables.
        try:
            self.customer_id = os.environ["OBSERVE_CUSTOMER_ID"]
            self.observe_domain = os.environ["OBSERVE_DOMAIN"]
            self.datastream_token = os.environ["OBSERVE_DATASTREAM_TOKEN"]
        except:
            logging.critical(
                "[ObserveClient] Required ENV_VARS are not set properly")
            exit(-1)

        # Optional environment variables with default value.
        self.max_batch_size_byte = int(
            os.getenv("OBSERVE_CLIENT_MAX_BATCH_SIZE_BYTE") or 512*1024)
        self.max_obs_per_batch = int(
            os.getenv("OBSERVE_CLIENT_MAX_OBS_PER_BATCH") or 256)
        self.max_retries = int(os.getenv("OBSERVE_CLIENT_MAX_RETRIES") or 5)
        self.max_timeout_sec = int(
            os.getenv("OBSERVE_CLIENT_MAX_TIMEOUT_SEC") or 10)

        self.reset_state()
        logging.info(
            f"[ObserveClient] Initialized a new client: "
            f"customer_id = {self.customer_id}, "
            f"domain = {self.observe_domain}, "
            f"max_batch_size_byte = {self.max_batch_size_byte}, "
            f"max_obs_per_batch = {self.max_obs_per_batch}")

    def reset_state(self):
        """
        Reset the state of the client.
        """
        self.num_obs_in_cur_batch = 0
        self.buf = io.StringIO()
        self.buf.write("[")

    def process_events(self, event_arr: func.EventHubEvent):
        """
        Parse and send all incoming events to Observe, with multiple batches
        if needed. Each batch is a single HTTP request containing an array of
        JSON observations.
        """
        if len(event_arr) == 0:
            logging.error("[ObserveClient] 0 event to process, skip")
            return

        # For cardinality=many scenarios, each event points to the common
        # metadata of all the events.
        if event_arr[0].metadata == {}:
            raise Exception(
                "Event metadata is missing for is function invocation")

        self.event_metadata = event_arr[0].metadata
        # Index of the starting event in current batch.
        batch_start_index = 0

        for e in event_arr:
            # Here we assume the event body is always a valid JSON, as described
            # in the Azure documentation.
            self.buf.write(e.get_body().decode())
            self.buf.write(",")
            self.num_obs_in_cur_batch += 1

            # Check whether we need to flush the current buffer to Observe.
            if self.num_obs_in_cur_batch >= self.max_obs_per_batch or \
                    self.buf.tell() >= self.max_batch_size_byte:
                self.buf.write(
                    self._build_batch_metadata_json(batch_start_index))
                # Update the start index for the next batch.
                batch_start_index += self.num_obs_in_cur_batch
                self.buf.write("]")
                self._send_batch()

        # Flush remaining data from the buffer to Observe.
        if self.num_obs_in_cur_batch > 0:
            self.buf.write(self._build_batch_metadata_json(batch_start_index))
            self.buf.write("]")
            self._send_batch()

        logging.info(f"[ObserveClient] {len(event_arr)} events processed.")

    def _build_batch_metadata_json(self, batch_start_index: int) -> str:
        """
        Construct a metadata observation for the current batch, as the last
        record in the JSON array.
        """
        if self.buf.tell() <= 0:
            raise Exception("Buffer should contain data but is empty")
        elif self.num_obs_in_cur_batch <= 0:
            raise Exception(
                "There should be at least 1 observation in current batch")

        batch_meta = {
            "ObserveNumEvents": self.num_obs_in_cur_batch,
            "ObserveTotalSizeByte": self.buf.tell(),
            "ObserveSubmitTimeUtc": str(datetime.utcnow()).replace(' ', 'T'),
            "AzureEventHubPartitionContext": self.event_metadata.get("PartitionContext", {}),
        }

        if "SystemPropertiesArray" not in self.event_metadata:
            batch_meta["AzureEventHubSystemPropertiesArray"] = {}
        else:
            # Get the sub array from the original metadata.
            batch_meta["AzureEventHubSystemPropertiesArray"] = self.event_metadata[
                "SystemPropertiesArray"][batch_start_index: batch_start_index+self.num_obs_in_cur_batch]

        return json.dumps(batch_meta, separators=(',', ':'))

    def _send_batch(self):
        """
        Wrap up the batch, and send the observations in the current buffer to
        Observe's collector endpoint.
        """
        if self.buf.tell() <= 0:
            raise Exception("Buffer should contain data but is empty")

        # Send the request.
        req_url = f"https://{self.customer_id}.collect.{self.observe_domain}/v1/http/azure?source=EventHubTriggeredFunction"
        s = requests.Session()
        s.mount(req_url, HTTPAdapter(max_retries=self.max_retries))
        response = s.post(
            req_url,
            headers={
                'Authorization': 'Bearer ' + self.datastream_token,
                'Content-type': 'application/json'},
            data=bytes(self.buf.getvalue().encode('utf-8')),
            timeout=self.max_timeout_sec
        )

        # Error handling.
        response.raise_for_status()

        logging.info(
            f"[ObserveClient] {self.num_obs_in_cur_batch} observations sent, "
            f"response: {response.json()}")
        self.reset_state()


def main(event: func.EventHubEvent):
    # Create an HTTP client, or load it from the cache.
    global OBSERVE_CLIENT
    if OBSERVE_CLIENT is None:
        OBSERVE_CLIENT = ObserveClient()
    else:
        OBSERVE_CLIENT.reset_state()

    # Process the array of new events.
    try:
        OBSERVE_CLIENT.process_events(event)
    except Exception as e:
        logging.critical(f"[ObserveClient] {str(e)}")
        exit(-1)
    except:
        logging.critical("[ObserveClient] Unknown error processing the events")
        exit(-1)
