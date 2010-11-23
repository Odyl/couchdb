% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

-module(couch_httpd_multiview).
-include("couch_db.hrl").

-import(couch_httpd,[send_json/2,send_method_not_allowed/2]).

-export([handle_multiview_req/1]).

handle_multiview_req(#httpd{method='POST'}=Req) ->
    inets:start(),
    couch_httpd:validate_ctype(Req, "application/json"),
    {PostJson} = couch_httpd:json_body_obj(Req),
    Results = get_query_results(Req, PostJson, []),
    inets:stop(),
    send_json(Req, {Results});

handle_multiview_req(Req) ->
    send_method_not_allowed(Req, "POST").

get_query_results(_Req, [], ResponseJson) -> ResponseJson;
get_query_results(Req, RequestJson, ResponseJson) ->
    [{Key,Val} | Rest] = RequestJson,
    Url = couch_httpd:absolute_uri(Req, "/") ++ binary_to_list(Val),
    Results = case httpc:request(Url) of
        {ok, {_Status, _Headers, Body}} ->
            DecodedBody = couch_util:json_decode(Body),
            {Key, DecodedBody};
        {error, _Reason} ->
            {Key, error}
    end,
    get_query_results(Req, Rest, [Results | ResponseJson]).

