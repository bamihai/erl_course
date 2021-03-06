
%% @doc Web server for ebank.

-module(ebank_web).
-author("Mochi Media <dev@mochimedia.com>").

-compile(tuple_calls).

-export([start/1, stop/0, loop/2]).

%% External API


-record(accountDetails, {name, balance, pin}).
-record(account, {id, details=accountDetails#{}}).

start(Options) ->
    {DocRoot, Options1} = get_option(docroot, Options),
    Loop = fun (Req) ->
                   ?MODULE:loop(Req, DocRoot)
           end,
    mochiweb_http:start([{name, ?MODULE}, {loop, Loop} | Options1]).

stop() ->
    mochiweb_http:stop(?MODULE).

loop(Req, DocRoot) ->
    "/" ++ Path = Req:get(path),
    try
        case Req:get(method) of
            Method when Method =:= 'GET'; Method =:= 'HEAD' ->
                case Path of
                  "hello_world" ->
                    Req:respond({200, [{"Content-Type", "text/plain"}], "Hello world!\n"});
		   "getBalance" ->
	            Accounts = mochiglobal:get(accounts),
		    Req:respond({200, [{"Content-Type", "text/plain"}], "{\"Balance\": 100}\n"});
                    _ ->
                        Req:serve_file(Path, DocRoot)
                end;
            'POST' ->
                case Path of
		   "create" ->
		   	QueryData = Req:parse_qs(),
			%[{id, Id}, {name, Name}, {pin, Pin}, {balance, Balance}] = QueryData,
			QueryKeys = proplists:get_keys(QueryData),
			[Id, Name, Balance, Pin] = lists:map(fun(X) -> proplists:get_value(X, QueryData) end, QueryKeys),
		   	Adet = #accountDetails{name=Name, balance=Balance, pin=Pin},
                   	Account = #account{id=Id, details=Adet},
			Accounts = mochiglobal:get(accounts),
			NewAccounts = [Account|Accounts],
			mochiglobal:put(accounts, Account);
                    _ ->
                        Req:not_found()
                end;
            _ ->
                Req:respond({501, [], []})
        end
    catch
        Type:What ->
            Report = ["web request failed",
                      {path, Path},
                      {type, Type}, {what, What},
                      {trace, erlang:get_stacktrace()}],
            error_logger:error_report(Report),
            Req:respond({500, [{"Content-Type", "text/plain"}],
                         "request failed, sorry\n"})
    end.

%% Internal API

get_option(Option, Options) ->
    {proplists:get_value(Option, Options), proplists:delete(Option, Options)}.

%%
%% Tests
%%
-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

you_should_write_a_test() ->
    ?assertEqual(
       "No, but I will!",
       "Have you written any tests?"),
    ok.

-endif.
