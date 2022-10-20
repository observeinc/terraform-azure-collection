#! /usr/local/bin/python3

import asyncio
import functools
import io
import json
import logging
import os
import requests

from datetime import datetime
from requests.adapters import HTTPAdapter


class BaseHandler:
    """
    Async base handler class that manages the data buffer and Observe HTTP
    client.
    """
    def __init__(self):
        # Optional environment variable with default value.
        self.max_req_size_byte = int(
            os.getenv("OBSERVE_CLIENT_MAX_REQ_SIZE_BYTE") or 512*1024)

        self.observe_client = ObserveClient()
        self._reset_state()
        self.source = "Unknown"

    def _reset_state(self):
        self.event_metadata = None
        self.num_obs = 0
        self.buf = io.StringIO()

    async def _wrap_buffer_and_send_request(self) -> None:
        timestamp = datetime.utcnow()
        self.buf.write(await self._build_req_metadata_json(timestamp))
        self.buf.write("]")

        extra = {
            "source": self.source,
            "timestamp": timestamp.strftime("%Y%m%d%H%M%S%f"),
        }
        # Send data to Observe.
        await self.observe_client.send_observations(payload=self.buf.getvalue(), extra=extra)

    async def _build_req_metadata_json(self, timestamp: datetime) -> str:
        """
        Construct a metadata observation for the current Observe request,
        as the last record in the JSON array.
        """
        if self.buf.tell() <= 0:
            raise Exception("Buffer should contain data but is empty")
        elif self.num_obs <= 0:
            raise Exception(
                "There should be at least 1 observation in current request")

        req_meta = {
            "ObserveNumObservations": self.num_obs,
            "ObserveTotalSizeByte": self.buf.tell(),
            "ObserveSubmitTimeUtc": timestamp.isoformat(),
            "AzureSource": self.source
        }

        # In case of EventHub triggered function.
        if self.event_metadata != None and self.source == "EventHub":
            req_meta["AzureEventHubPartitionContext"] = self.event_metadata.get(
                "PartitionContext", {})
            if "SystemPropertiesArray" not in self.event_metadata:
                req_meta["AzureEventHubSystemPropertiesArray"] = {}
                req_meta["ObserveNumEvents"] = 0
            else:
                req_meta["AzureEventHubSystemPropertiesArray"] = self.event_metadata["SystemPropertiesArray"]
                req_meta["ObserveNumEvents"] = len(
                    self.event_metadata["SystemPropertiesArray"])

        return json.dumps(req_meta, separators=(',', ':'))


class ObserveClient:
    """
    Async Client that sends the observation payloads (an array ) to Observe's
    HTTP collector endpoint.
    """

    def __init__(self):
        # Required environment variables.
        try:
            self.observe_customer = os.environ["OBSERVE_CUSTOMER"]
            self.observe_token = os.environ["OBSERVE_TOKEN"]
            self.observe_domain = os.environ["OBSERVE_DOMAIN"]
        except:
            logging.critical(
                "[ObserveClient] Required ENV_VARS are not set properly")
            exit(-1)

        # Optional environment variables.
        self.max_retries = int(os.getenv("OBSERVE_CLIENT_MAX_RETRIES") or 5)
        self.max_timeout_sec = int(
            os.getenv("OBSERVE_CLIENT_MAX_TIMEOUT_SEC") or 10)

        logging.info(
            f"[ObserveClient] Initialized a new client: "
            f"observe_customer = {self.observe_customer}, "
            f"domain = {self.observe_domain}, "
            f"max_retries = {self.max_retries}, "
            f"max_timeout_sec = {self.max_timeout_sec}")

    async def send_observations(self, payload: str, extra: dict) -> None:
        if len(payload) == 0:
            raise Exception("[ObserveClient] Request payload is empty")

        # Convert EXTRA into URL params.
        params = dict_to_url_params(extra)
        req_url = f"https://{self.observe_customer}.collect.{self.observe_domain}/v1/http/azure{params}"

        # DEBUGGING: Print out the data instead of sending it to Observe.
        if os.getenv("DEBUG_OUTPUT") == 'true':
            logging.critical(f"[ObserveClient] {payload}")
            logging.critical(f"[ObserveClient] URL: {req_url}")
            return

        # Send the request.
        s = requests.Session()
        s.mount(req_url, HTTPAdapter(max_retries=self.max_retries))

        loop = asyncio.get_event_loop()
        future = loop.run_in_executor(
            None,
            functools.partial(
                s.post,
                req_url,
                headers={
                    'Authorization': 'Bearer ' + self.observe_token,
                    'Content-type': 'application/json'},
                data=bytes(payload.encode('utf-8')),
                timeout=self.max_timeout_sec)
        )
        response = await future
        # Error handling.
        response.raise_for_status()

        logging.info(
            f"[ObserveClient] Observations sent, response: {response.json()}")


def dict_to_url_params(input: dict) -> str:
    """
    Convert {"param1": "val1", "param2": "val2"} to ?param1=val1&param2=vale
    """
    if len(input) == 0:
        return ""
    else:
        return "?" + '&'.join(f'{key}={value}' for key, value in input.items())