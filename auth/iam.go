// Copyright 2023 Versity Software
// This file is licensed under the Apache License, Version 2.0
// (the "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package auth

import (
	"errors"
)

// Account is a gateway IAM account
type Account struct {
	Secret string `json:"secret"`
	Role   string `json:"role"`
}

// IAMService is the interface for all IAM service implementations
type IAMService interface {
	CreateAccount(access string, account Account) error
	GetUserAccount(access string) (Account, error)
	DeleteUserAccount(access string) error
}

var ErrNoSuchUser = errors.New("user not found")
