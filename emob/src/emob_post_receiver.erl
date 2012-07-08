%%%-------------------------------------------------------------------
%%% @author Juan Jose Comellas <juanjo@comellas.org>
%%% @author Mahesh Paolini-Subramanya <mahesh@dieswaytoofast.com>
%%% @author Tom Heinan <me@tomheinan.com>
%%% @copyright (C) 2011-2012 Juan Jose Comellas, Mahesh Paolini-Subramanya
%%% @doc Processing when each post is received
%%% @end
%%%
%%% This source file is subject to the New BSD License. You should have received
%%% a copy of the New BSD license with this software. If not, it can be
%%% retrieved from: http://www.opensource.org/licenses/bsd-license.php
%%%-------------------------------------------------------------------
-module(emob_post_receiver).

-author('Juan Jose Comellas <juanjo@comellas.org>').
-author('Mahesh Paolini-Subramanya <mahesh@dieswaytoofast.com>').
-author('Tom Heinan <me@tomheinan.com>').

-behaviour(gen_server).

-compile([{parse_transform, lager_transform}]).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([process_post/1]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% Includes & Defines
%% ------------------------------------------------------------------
-include("defaults.hrl").

-record(post_receiver_state, {
            stream_pid
            }).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------


%% @doc Process the incoming tweet
%%          sent to Target
process_post(Post) ->
    emob_manager:safe_cast({?EMOB_POST_RECEIVER, ?EMOB_POST_RECEIVER}, {process_post, Post}).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

start_link(Token, Secret) ->
    gen_server:start_link(?MODULE, [Token, Secret], []).

init([Token, Secret]) ->
    process_flag(trap_exit, true),
    emob_manager:register_process(?EMOB_POST_RECEIVER, ?EMOB_POST_RECEIVER),
    DestPid = self(),
    process_tweets(DestPid, Token, Secret),

    State = #post_receiver_state{},
    {ok, State}.

    

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({process_post, Tweet}, State) ->
    % TODO error?
    lager:debug("2,process_post  Tweet:~p~n", [Tweet]),
    PostId = Tweet#tweet.id,
    case app_cache:key_exists(?POST, PostId) of
        false ->
            PostRecord = #post{
                    id = PostId,
                    post_data = Tweet},
            app_cache:set_data(PostRecord),
%            twitterl_post_distributor:distribute_post(PostId);
            ok;
        true ->
            ok
    end,
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% @doc Get the tweet from twitterl
handle_info(Tweet, State) when is_record(Tweet, tweet) ->
    process_post(Tweet),
    {noreply, State};

handle_info({'EXIT',  _Pid, _Reason}, State) ->
    lager:error("twitterl streamer exited~n", []),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

-spec process_tweets(pid(), token(), secret()) -> ok | pid().
process_tweets(DestPid, Token, Secret) ->
    SinceId = 
    case app_cache:get_last_data(?POST) of
        [] ->
            ?FIRST_POST;
        [Post] ->
            Post#post.id
    end,
    SSinceId = emob_util:get_string(SinceId),
    proc_lib:spawn_link(fun() -> 
                timer:sleep(?STARTUP_TIMER),
                twitterl:statuses_home_timeline({process, DestPid}, [{"since_id", SSinceId}], Token, Secret),
                twitterl:statuses_user_timeline_stream({process, DestPid}, [], Token, Secret) 
        end).