#!/usr/bin/env bash

# Copyright 2024 Versity Software
# This file is licensed under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

source ./tests/rest_scripts/rest.sh

# Fields

# shellcheck disable=SC2153
bucket_name="$BUCKET_NAME"
# shellcheck disable=SC2153
key="$OBJECT_KEY"
# shellcheck disable=SC2153,SC2034
upload_id="$UPLOAD_ID"
# shellcheck disable=SC2153
parts="$PARTS"

payload="<CompleteMultipartUpload xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">$parts</CompleteMultipartUpload>"
payload_hash="$(echo -n "$payload" | sha256sum | awk '{print $1}')"
current_date_time=$(date -u +"%Y%m%dT%H%M%SZ")

canonical_request="POST
/$bucket_name/$key
uploadId=$UPLOAD_ID
host:$host
x-amz-content-sha256:$payload_hash
x-amz-date:$current_date_time

host;x-amz-content-sha256;x-amz-date
$payload_hash"

create_canonical_hash_sts_and_signature

curl_command+=(curl -ks -w "\"%{http_code}\"" -X POST "$AWS_ENDPOINT_URL/$bucket_name/$key?uploadId=$upload_id"
-H "\"Authorization: AWS4-HMAC-SHA256 Credential=$aws_access_key_id/$year_month_day/$aws_region/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=$signature\""
-H "\"x-amz-content-sha256: $payload_hash\""
-H "\"x-amz-date: $current_date_time\""
-H "\"Content-Type: application/xml\""
-d "\"${payload//\"/\\\"}\""
-o "$OUTPUT_FILE")
# shellcheck disable=SC2154
eval "${curl_command[*]}" 2>&1
