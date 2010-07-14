%%   The contents of this file are subject to the Mozilla Public License
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%   The Original Code is RabbitMQ Management Console.
%%
%%   The Initial Developers of the Original Code are LShift Ltd.
%%
%%   Copyright (C) 2009 LShift Ltd.
%%
%%   All Rights Reserved.
%%
%%   Contributor(s): ______________________________________.
%%
-module(rabbit_management_overview).

-export([init/1, to_json/2, content_types_provided/2, is_authorized/2]).

-include_lib("webmachine/include/webmachine.hrl").
-include_lib("rabbit_common/include/rabbit.hrl").

%%--------------------------------------------------------------------

init(_Config) -> {ok, undefined}.
%%init(_Config) -> {{trace, "/tmp"}, undefined}.

content_types_provided(ReqData, Context) ->
   {[{"application/json", to_json}], ReqData, Context}.

to_json(ReqData, Context) ->
    Keys = [datetime, bound_to, fd_used, fd_total,
            mem_used, mem_total, proc_used, proc_total],
    rabbit_management_util:apply_cache_info(
      Keys, ReqData, Context,
      fun(I) ->
              {struct,
               [{node, node()},
                {pid, list_to_binary(os:getpid())},
                {datetime, list_to_binary(I(datetime))},
                {bound_to, list_to_binary(I(bound_to))},
                {fd_used, I(fd_used)},
                {fd_total, I(fd_total)},
                {mem_used, I(mem_used)},
                {mem_total, I(mem_total)},
                {proc_used, I(proc_used)},
                {proc_total, I(proc_total)},
                {fd_warn, get_warning_level(I(fd_used), I(fd_total))},
                {mem_warn, get_warning_level(I(mem_used), I(mem_total))},
                {proc_warn, get_warning_level(I(proc_used), I(proc_total))},
                {mem_ets, erlang:memory(ets)},
                {mem_binary, erlang:memory(binary)}
               ]}
      end).

is_authorized(ReqData, Context) ->
    rabbit_management_util:is_authorized(ReqData, Context).

%%--------------------------------------------------------------------

get_warning_level(Used, Total) ->
    if
        is_number(Used) andalso is_number(Total) ->
            Ratio = Used/Total,
            if
                Ratio > 0.75 -> red;
                Ratio > 0.50 -> yellow;
                true         -> green
            end;
        true -> none
    end.