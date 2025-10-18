#!/usr/bin/env bats

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

source ./tests/drivers/create_bucket/create_bucket_rest.sh

if [ "$SKIP_ACL_TESTING" == "true" ] || [ "$SKIP_USERS_TESTS" == "true" ]; then
  skip "Skipping ACL tests"
  exit 0
fi

test_put_bucket_acl_s3cmd() {
  if [ "$DIRECT" != "true" ]; then
    skip "https://github.com/versity/versitygw/issues/963"
  fi

  run setup_bucket "$BUCKET_ONE_NAME"
  assert_success

  username=$USERNAME_ONE
  if [[ $DIRECT != "true" ]]; then
    run setup_user "$username" "HIJKLMN" "user"
    assert_success
  fi
  sleep 5

  run get_check_default_acl_s3cmd "$BUCKET_ONE_NAME"
  assert_success

  if [[ $DIRECT == "true" ]]; then
    run put_public_access_block_enable_public_acls "$BUCKET_ONE_NAME"
    assert_success
  fi
  run put_bucket_canned_acl_s3cmd "$BUCKET_ONE_NAME" "--acl-public"
  assert_success

  run get_check_post_change_acl_s3cmd "$BUCKET_ONE_NAME"
  assert_success
}

get_grantee_type_and_id() {
  if [[ $DIRECT == "true" ]]; then
    grantee_type="Group"
    grantee_id="http://acs.amazonaws.com/groups/global/AllUsers"
  else
    grantee_type="CanonicalUser"
    grantee_id="$username"
  fi
}

test_common_put_bucket_acl() {
  run check_param_count "test_common_put_bucket_acl" "client type" 1 "$#"
  assert_success

  run get_bucket_name "$BUCKET_ONE_NAME"
  assert_success
  # shellcheck disable=SC2154
  bucket_name="$output"

  run setup_bucket_and_user "$bucket_name" "$USERNAME_ONE" "$PASSWORD_ONE" "user"
  assert_success
  # shellcheck disable=SC2154
  username="${lines[${#lines[@]}-2]}"

  run put_bucket_ownership_controls "$bucket_name" "BucketOwnerPreferred"
  assert_success

  run get_check_acl_id "$1" "$bucket_name"
  assert_success

  acl_file="test-acl"
  run create_test_files "$acl_file"
  assert_success

  get_grantee_type_and_id
  run setup_acl_json "$TEST_FILE_FOLDER/$acl_file" "$grantee_type" "$grantee_id" "READ" "$AWS_ACCESS_KEY_ID"
  assert_success

  log 5 "acl: $(cat "$TEST_FILE_FOLDER/$acl_file")"
  run put_bucket_acl_s3api "$bucket_name" "$TEST_FILE_FOLDER"/"$acl_file"
  assert_success

  run get_check_acl_after_first_put "$1" "$bucket_name"
  assert_success

  run setup_acl_json "$TEST_FILE_FOLDER/$acl_file" "CanonicalUser" "$username" "FULL_CONTROL" "$AWS_ACCESS_KEY_ID"
  assert_success

  run put_bucket_acl_s3api "$bucket_name" "$TEST_FILE_FOLDER"/"$acl_file"
  assert_success

  run get_check_acl_after_second_put "$1" "$bucket_name"
  assert_success
}