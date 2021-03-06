%%%-------------------------------------------------------------------
%%% File    : fs_fixture_server.erl
%%%
%%% @doc  A process for aid in creating a test fixture.
%%% Keeps state so that test writers don't have to.
%%% @end
%%%
%%%-------------------------------------------------------------------
-module(fs_fixture_server).

-behaviour(gen_server).
%%--------------------------------------------------------------------
%% Include files
%%--------------------------------------------------------------------
-include("fs_test_lib.hrl").
-include("macros.hrl").

%%--------------------------------------------------------------------
%% External exports
%%--------------------------------------------------------------------
-export([
         start/1,
         start_link/1,
         stop/0,
         view_state/2,
         view_state/1,
         stop_release/1,
         start_release/4,
         start_release/3,
         start_release/2
         ]).

%%--------------------------------------------------------------------
%% gen_server callbacks
%%--------------------------------------------------------------------
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%--------------------------------------------------------------------
%% record definitions
%%--------------------------------------------------------------------

%%--------------------------------------------------------------------
%% macro definitions
%%--------------------------------------------------------------------
-define(SERVER, ?MODULE).

%% Control where the default script and boot dir is.
-define(SCRIPT_AND_BOOT_DIR(PathToOtpString, ReleaseName), PathToOtpString ++ "/releases/" ++ ReleaseName ++ "/local").

%%====================================================================
%% External functions
%%====================================================================
%%--------------------------------------------------------------------
%% @doc Starts the server.
%% <pre>
%% Variables:
%%  TSConfig - Generated by the test server for each test. The user of the fixture server may add one extra parameter in the form
%%             of {otp_dir, PathToOtpString} if this is not included the PathToOtpString will default to "DataDir" ++ "/../../"
%%             This will direct the fixture server to look for releases in PathToOtpString ++ "/releases/".
%% </pre>
%% @spec start_link(TSConfig) -> {ok, pid()} | {error, Reason}
%% @end
%%--------------------------------------------------------------------
start_link(TSConfig) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [TSConfig], []).

%%--------------------------------------------------------------------
%% @doc Starts the server. Starting this server will create a data dir just underneith the dir that the SUITE file resides in.
%% <pre>
%% Variables:
%%  TSConfig - Generated by the test server for each test. The user of the fixture server may add one extra parameter in the form
%%             of {otp_dir, PathToOtpString} if this is not included the PathToOtpString will default to "DataDir" ++ "/../../"
%% </pre>
%% @spec start(TSConfig) -> {ok, pid()} | {error, Reason}
%% @end
%%--------------------------------------------------------------------
start(TSConfig) ->
    gen_server:start({local, ?SERVER}, ?MODULE, [TSConfig], []).

%%--------------------------------------------------------------------
%% @doc Stops the server.
%% @spec stop() -> ok
%% @end
%%--------------------------------------------------------------------
stop() ->
    gen_server:call(?SERVER, stop, infinity).

%%--------------------------------------------------------------------
%% @doc Start a node of a particular release type.
%% <pre>
%% Note* I choose atoms for the node related args to this functions 
%%       because node names are usually atoms and I want to maintain
%%       consistancy with erlang conventions.
%%
%% Variables:
%%  ReleaseName - The name of the release to start. Example gq_rel.
%%  NodeName - What to name the node the release resides in.
%%  ExtraArgs - a string of extra arguments to append to the startup directives for the release.
%%  Options - are tuples of consisting of key value pairs used to set the internal state for a release.
%%
%% Types:
%%  ReleaseName = atom() example: galaxy_parser_rel
%%  NodeName = atom() example: zubin_galaxy_parser
%%  ExtraArgs = string() example: "-port 1000"
%%  LongNodeName = atom() example: 'zubin_galaxy_parser@localhost'
%%  Options = {Option, term()}
%%   Option = contact_node | script_and_boot_dir | death_treatment
%%
%% Explanation of Options:
%%  contact_node - the node that resource_discovery will ping to get into a cloud. This defaults to the test server node.
%%  script_and_boot_dir - This tells the system what directory the script and boot files for starting the release reside.
%%  death_treatment - This is how a release is to be treated on an unsolicited death. The 
%%                    options for this are permanent | temporary. permanent causes the fixture server to to shutdown.
%%                    temporary releases do not cause the fixture server to die.
%%                    
%%
%% </pre>
%% @spec start_release (ReleaseName, NodeName, ExtraCommandlineArgs, Options) -> {ok, LongNodeName} | {error, Reason}
%% @end
%%--------------------------------------------------------------------
start_release (ReleaseName, NodeName, ExtraCommandlineArgs, Options) 
  when is_list (Options), is_atom (NodeName), is_atom (ReleaseName), is_list (ExtraCommandlineArgs) ->
    gen_server:call (?SERVER, {start_release, {ReleaseName, NodeName, ExtraCommandlineArgs, Options}}, 20000).

%% @spec start_release (ReleaseName, NodeName, ExtraCommandlineArgs) -> {ok, LongNodeName}
%% @equiv start_release (ReleaseName, NodeName, ExtraCommandlineArgs, [])
start_release (ReleaseName, NodeName, ExtraCommandlineArgs) ->
    start_release (ReleaseName, NodeName, ExtraCommandlineArgs, []).

%% @spec start_release (ReleaseName, NodeName) -> {ok, LongNodeName}
%% @equiv start_release (ReleaseName, NodeName, "", [])
start_release (ReleaseName, NodeName) ->
    start_release (ReleaseName, NodeName, "", []).

%%--------------------------------------------------------------------
%% @doc Stop a particular node.
%% <pre>
%% Types:
%%  NodeName = atom() example: zubin_galaxy_parser
%% </pre>
%% @spec stop_release(NodeName) -> ok | error
%% @end
%%--------------------------------------------------------------------
stop_release(NodeName) ->
    gen_server:call(?SERVER, {stop_release, NodeName}).
    

%%--------------------------------------------------------------------
%% @doc Veiw internal state values. If a NodeName is not provided it is assumed that the value pertains to all
%% releases tracked by the fixture server.
%% <pre>
%% Variables:
%%  ReleaseName - The name of the release to start. Example gq_rel.
%%  StateValueName - are the key names for internal state values.
%%
%% Types:
%%  ReleaseName = atom() example: galaxy_parser_rel
%%  StateValueName = name     | node_name    | sasl_log | 
%%                   err_log  | contact_node | script_and_boot_dir | 
%%                   data_dir | priv_dir     | long_node_name
%%
%% Explanation of non obvious StateValueNames:
%%  contact_node - the node that resource_discovery will ping to get into a 
%%                 cloud. This defaults to the test server node.
%%  script_and_boot_dir - This tells the system what directory the script and 
%%                        boot files for starting the release reside.
%%  data_dir - This is the place that you would put your test specific static 
%%             data files. Always the dir below the location of the SUITE file.
%%  priv_dir - The directory that you get when ever you run a test it is used 
%%             for the storage of any temp files. Always a subdir of where the 
%%             test was run from.
%%
%% </pre>
%% @spec view_state(NodeName, StateValueName) -> {ok, Value} | {error, Reason}
%% @end
%%--------------------------------------------------------------------
view_state(NodeName, StateValueName) -> 
    gen_server:call(?SERVER, {view_state, {NodeName, StateValueName}}).

%% @spec view_state(StateValueName) -> {ok, Value} | {error, Reason}
%% @equiv view_state(global_state, StateValueName)
view_state(StateValueName) -> 
    view_state('$global_state', StateValueName).
    
%%====================================================================
%% Server functions
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%%--------------------------------------------------------------------
init([TSConfig]) ->
	io:format("fs_fixture_server:init/1~n"),

    %% This is to protect againsed failing ports sending us exit signals.
    process_flag(trap_exit, true),
    {_, {_, DataDir}} = lists:keysearch (data_dir, 1, TSConfig),
    {_, {_, PrivDir}} = lists:keysearch (priv_dir, 1, TSConfig),
    PathToOtpString   = fs_lists:get_val(otp_dir, TSConfig, DataDir ++ "/../../"),

    %% Create the data dir
    catch file:make_dir(DataDir),

    {ok, #state{data_dir = DataDir, priv_dir = PrivDir, otp_dir = PathToOtpString, releases = dict:new()}}.

%%--------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%%--------------------------------------------------------------------
handle_call({start_release, {ReleaseName, NodeName, ExtraCommandlineArgs, Options} = Args}, From, #state{data_dir = DataDir, priv_dir = PrivDir, otp_dir = PathToOtpString, releases = Releases} = State) ->
    
    io:format("fs_fixture_server:handle_call for start_release Args ~p~n", [Args]),
    case dict:is_key(NodeName, Releases) of
        true  -> 
			io:format("fs_fixture_server:handle_call the release has already been started~n"),
            %% A node/release has already been started by that node name.
            {reply, {error, ealreadyexists}, State};
        false -> 
            %% Create state values for this release.
            StringReleaseName = atom_to_list(ReleaseName),
            StringNodeName    = atom_to_list(NodeName),
            SaslLog           = test_server:temp_name (PrivDir ++ "/" ++ StringNodeName ++ "_sasl_log_"),
            ErrLog            = test_server:temp_name (PrivDir ++ "/" ++ StringNodeName ++ "_err_log_"),
            DfltScriptBootDir = ?SCRIPT_AND_BOOT_DIR(PathToOtpString, StringReleaseName),
            ScriptAndBootDir  = search_opts(script_and_boot_dir, Options, DfltScriptBootDir),
            ContactNode       = search_opts(contact_node, Options, node()),
            DeathTreatment    = search_opts(death_treatment, Options, permanent),
            ConfigFile        = search_opts(config_file, Options, ReleaseName),
	    io:format("Release Name: ~p~n", [ReleaseName]), 
	    io:format("Config Name: ~p~n", [ConfigFile]), 
            Release           = #release{name         = ReleaseName, node_name           = NodeName, 
                                         sasl_log     = SaslLog,     err_log             = ErrLog, 
                                         contact_node = ContactNode, script_and_boot_dir = ScriptAndBootDir,
                                         config_file  = ReleaseName, 
                                         death_treatment     = DeathTreatment},
            
            %% Create the command to start the release then attemt to start it. We must cd to the directory where the script and boot
            %% files reside in order to run the command. As soon as the node is started then return to pwd()
            Command = fs_test_lib:create_base_node_command(Release) ++ ExtraCommandlineArgs,
            io:format("command ~p~n", [Command]),
            {ok, LongNodeName} = fs_test_lib:start_node(NodeName, Command),

	    %% Add links to the err_log and sasl_log files to the test results.
	    io:fwrite ("<a href=\"~s\">~p SASL Log</a>", [SaslLog, LongNodeName]),
	    io:fwrite ("<a href=\"~s\">~p Error Log</a>", [ErrLog, LongNodeName]),
	    
	    %% Wait until the new node joins the test cloud.
	    fs_test_lib:poll_until(fun() -> io:format("waiting for node ~p to join ~p cloud with cookie ~p ~p~n", [LongNodeName, nodes(), auth:get_cookie(), net_adm:ping(LongNodeName)]),  lists:member(LongNodeName, nodes()) end, 60, 500),
                    
	    NewReleases  = dict:append(NodeName, Release, Releases),
	    
	    {reply, {ok, LongNodeName}, State#state{releases = dict:store(NodeName, Release#release{long_node_name = LongNodeName}, Releases)}}
    end;

handle_call({view_state, {NodeName, data_dir}},       From, #state{data_dir = DataDir}  = State)  -> {reply, {ok, DataDir}, State};
handle_call({view_state, {NodeName, priv_dir}},       From, #state{priv_dir = PrivDir}  = State)  -> {reply, {ok, PrivDir}, State};
handle_call({view_state, {NodeName, otp_dir}},        From, #state{otp_dir  = OtpDir}   = State)  -> {reply, {ok, OtpDir}, State};
handle_call({view_state, {'$global_state', Unknown}}, From, #state{data_dir = DataDir}  = State)  -> {reply, {error, notglobalstate}, State};
handle_call({view_state, {NodeName, StateValueName}}, From, #state{releases = Releases} = State)  ->
    case dict:find(NodeName, Releases) of
        error -> 
            {reply, {error, nodename}, State};
        {ok, Release} -> 
            case catch fs_test_lib:fetch_release_value(StateValueName, Release) of
                {'EXIT', Reason} -> {reply, {error, statevaluename}, State};
                Value            -> {reply, {ok, Value}, State}
            end
    end;
handle_call({stop_release, NodeName}, From, #state{releases = Releases} = State) ->
    Reply = 
    case dict:find(NodeName, Releases) of
        error       -> error;
        {ok, Value} ->
            case fs_test_lib:stop_node(Value#release.long_node_name) of
                true  -> ok;
                false -> error
            end
    end,
    {reply, Reply, State#state{releases = dict:erase(NodeName, Releases)}};
handle_call(stop, From, #state{releases = Releases} = State) ->
    {stop, normal, ok, State#state{releases = kill_all(Releases)}}.


%%--------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%%--------------------------------------------------------------------
handle_cast(Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%%--------------------------------------------------------------------
handle_info({'EXIT',Pid, {node_down, {port_closed, NodeName}}} = Exit, #state{releases = Releases} = State) ->
    io:format("fixture_server:handle_info received ~p with reason port_closed~n", [Exit]),
    {noreply, State};
handle_info({'EXIT',Pid, {node_down, {Reason, NodeName}}} = Exit, #state{releases = Releases} = State) ->
    case dict:find(NodeName, Releases) of
        error -> 
            io:format("fixture_server:handle_info received ~p with reason ~p~n", [Exit, Reason]),
            {noreply, State};
        {ok, #release{death_treatment = temporary} = Release} ->
            io:format("ERROR: fixture_server:handle_info received temporary release ~p unexpectedly with reason ~p~n", [Exit, Reason]),
            {noreply, State#state{releases = dict:erase(NodeName, Releases)}};
        {ok, #release{death_treatment = permanent} = Release} ->
            io:format("ERROR: fixture_server:handle_info received permanent release ~p unexpectedly with reason ~p~n", [Exit, Reason]),
            {stop, unexpected_node_failure, State#state{releases = dict:erase(NodeName, Releases)}}
    end.

%%--------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%%--------------------------------------------------------------------
%% Clean up all of the nodes.
terminate(Reason, #state{releases = Releases}) ->
    %%io:format("fs_fixture_server:terminate stopping all nodes~n"),
    %%kill_all(Releases).
    ok.

%%--------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%%--------------------------------------------------------------------
code_change(OldVsn, State, Extra) ->
    {ok, State}.

%%%==========================================================
%%% Internal functions
%%%==========================================================

%% Very nice and declaritive from a callers perspective. 
%% Find a value in the options if it is not presant then return the default value.
search_opts(Key, Options, Default) ->
    case lists:keysearch(Key, 1, Options) of
        {value, {Key, Value}} -> Value;
        false                 -> Default
    end.
    
%% Kill all the nodes in state.
kill_all(Releases) ->
    NodeNames = dict:fetch_keys(Releases),
    io:format("fs_fixture_server:kill_all nodes to kill ~p~n", [NodeNames]),
    kill_all(Releases, NodeNames).

kill_all(Releases, [NodeName|T]) -> kill_all(kill(Releases, NodeName), T);
kill_all(Releases, [])           -> Releases.

%% Stop a node. Erase it from releases.
%% Returns: NewReleases | exit()
kill(Releases, NodeName) ->
    LongNodeName = fs_test_lib:fetch_release_value(long_node_name, dict:fetch(NodeName, Releases)),
    true = fs_test_lib:stop_node(LongNodeName),
    dict:erase(NodeName, Releases).


























