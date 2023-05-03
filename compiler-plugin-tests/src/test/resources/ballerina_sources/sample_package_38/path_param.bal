// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

service /path/positive on listenerEP {

    resource function get case1/["value1"|"value2" path]() {}

    resource function get case2/[Value path]() {}

    resource function get case3/[EnumValue path]() {}

    resource function get case4/[1|2... paths]() {}

    resource function get case5/[Value... paths]() {}

    resource function get case6/[EnumValue... paths]() {}

    resource function get case7/[EnumValue|string path]() {}

    resource function get case8/[EnumValue|"value3" path]() {}

    resource function get case9/[UnionType path]() {}

    resource function get case10/[(Value|EnumValue)... paths]() {}
}

service /path/negative on listenerEP {

    resource function get case1/["value1"|4|3.5d path]() {}

    resource function get case2/[MixedValue path]() {}

    resource function get case3/[MixedValue... path]() {}
}
