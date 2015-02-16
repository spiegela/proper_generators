%%% @author Aaron Spiegel
%%% @copyright 2015 Aaron Spiegel spiegela ++ [$@|gmail.com]
%%% 
%%% == License ==
%%% The MIT License
%%%
%%% Copyright (c) 2015 Aaron Spiegel
%%% 
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%% 
%%% The above copyright notice and this permission notice shall be included in
%%% all copies or substantial portions of the Software.
%%% 
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%%% THE SOFTWARE.
-module(proplist_generators).

-compile(export_all).

%%% Generators

%% @doc
%% Generate a simple 2-element property.
%% @end
property() ->
  ?LET(Prop, {atom(), term()}, Prop).

%% @doc
%% Generate a proplist with 2-element properties.
%% @end
proplist() ->
  ?LET(Plist, list(property()), Plist).

%% @doc
%% Generate a proplist in which a returned (and therefore identifiable) field
%% exists.
%% @end
present_field() ->
  ?LET( {Field, Value, {Plist1, Plist2}},
        {atom(), term(), split_proplist()},
        {Field, splice_into({Field, Value}, Plist1, Plist2)}
      ).

%% @doc
%% Generate a proplist in which a provided field exists.
%% @end
present_field(Field) ->
  ?LET( {Value, {Plist1, Plist2}},
        {term(), split_proplist(Field)},
        {Field, splice_into({Field, Value}, Plist1, Plist2)}
      ).

%% @doc
%% Generate a proplist in which a provided field with a provided value exists.
%% @end
present_field(Field, {value, Value}) ->
  ?LET( {Plist1, Plist2},
        split_proplist(Field),
        {Field, splice_into({Field, Value}, Plist1, Plist2)}
      ).

%% @doc
%% Generate a proplist and split it into two (at random).
%% @end
split_proplist() ->
  ?LET(Plist, proplist(), split_at_random(Plist)).

%% @doc
%% Generate a proplist excluding a specified field, split into two random parts.
%% @end
split_proplist(Field) ->
  ?LET(Plist, missing_field(Field), split_at_random(Plist)).

%% @doc
%% Generate a proplist in which a specified field is missing.
%% @end
missing_field(Field) ->
  ?SUCHTHAT(Plist, proplist(), is_not_a_key(Field, Plist)).

%% @doc
%% Generate a proplist in which a returned (and therefore identifiable)
%% field is missing.
%% @end
missing_field() ->
  ?SUCHTHAT({Field, Plist}, field_lookup(), is_not_a_key(Field, Plist)).

%% @doc
%% Generate a random field and a random property list.
%% @end
field_lookup() -> {atom(), proplist()}.

%% @doc
%% Generate a proplist in which a specified field is not included in the another list
%% of elements.
%% @end
excluded_field() ->
  ?SUCHTHAT( {{Field, Plist}, InList},
             {present_field(), list()},
             value_is_not_included(Field, Plist, InList)
           ).

%% @doc
%% Generate a proplist in which a returns (and therefore identifiable) field is
%% included in another list of elements.
included_field() ->
  ?LET( {{Field, Plist}, {InList1, InList2}},
        {present_field(), split_list()},
        {{Field, Plist}, splice_value_into(Field, Plist, InList1, InList2)}
      ).

%% @doc
%% Generate a proplist and field in which the field value does not match a
%% generated regular expression
%% @end
unmatching_field() ->
  ?LET( {Field, {Binary, Regex}},
        {atom(), unmatching_regex()},
        {present_field(Field, {value, Binary}), Regex}
      ).


%% @doc
%% Generate a proplist and field in which the field value matches a
%% generated regular expression
%% @end
matching_field() ->
  ?LET( {Field, {Binary, Regex}},
        {atom(), matching_regex()},
        {present_field(Field, {value, Binary}), Regex}
      ).

%% @doc
%% Generate a proplist and then split it into equal parts.  Why not just generate
%% two lists?  I don't know.... I guess I wasn't thinking.  It might help with creating
%% relatively smaller lists when growing test sets, though.
%% @end
split_list() -> ?LET(List, list(), split_at_random(List)).

%% @doc
%% Generate a binary string that doesn't match a generated regex.
%% @end
unmatching_regex() ->
  ?SUCHTHAT( {Binary, Regex},
             {escaped_utf8_bin(), regex_string()},
             regex_does_not_match(Binary, Regex)
           ).

%% @doc
%% Generate a binary string that matches a generated regex.
%% @end
matching_regex() ->
  ?LET( {String1, String2, Regex},
        {regex_string(), regex_string(), regex_string()},
        {list_to_binary(splice_into(Regex, String1, String2)), Regex}
      ).

%% @doc
%% Generate a re-compatible regex.
%% @end
regex_string() ->
  default("0",list(union([range($a, $z), range($A, $Z), range($0, $9)]))).

%% @doc
%% Generate a valid utf8 binary string.
%% @end
escaped_utf8_bin() ->
  ?SUCHTHAT( Bin,
             ?LET(S, ?SUCHTHAT(L, list(escaped_char()), L /= []),
                  unicode:characters_to_binary(S, unicode, utf8)),
             is_binary(Bin)
           ).

%% @doc
%% Generate an escaped utf8 character.
%% @end
escaped_char() ->
  ?LET( C, char(),
        case C of
          $" -> "\\\"";
          C when C == 65534 -> 65533;
          C when C == 65535 -> 65533;
          C when C > 1114111 -> 1114111;
          C -> C
        end
      ).

%% @doc
%% Generate a proplist in which a field value is a string with a length other than
%% the generated length.
%% @end
field_with_bad_length() ->
  ?LET( {Field, {String, Length}},
        {atom(), string_with_bad_length()},
        {present_field(Field, {value, String}), Length}
      ).

%% @doc
%% Generate a string with a length other than the generated length.
%% @end
string_with_bad_length() ->
  ?SUCHTHAT( {String, Length},
             {string(), non_neg_integer()},
             length(String) =/= Length
           ).

%%% Helpers

%% @doc
%% Insert an element into two lists
%% @end
-spec splice_into(term(), list(), list()) -> list().
splice_into(Elem, List1, List2) -> lists:concat([List1, [Elem], List2]).

%% @doc
%% Split a list at random index
%% @end
-spec splice_into(list()) -> {list(), list()}.
split_at_random([]) -> {[], []};
split_at_random(List) -> lists:split(random_index(List), List).

%% @doc
%% Get an index within a list
%% @end
-spec random_integer(list()) -> non_neg_integer().
random_index(List) -> random:uniform(length(List)).

%% @doc
%% Test a proplist to see if a key is included
%% @end
-spec is_not_a_key(term(), proplists:proplist()) -> boolean().
is_not_a_key(Field, Plist) -> not lists:keymember(Field, 1, Plist).

%% @doc
%% Splice value from proplist (based on provided field) into two lists
%% @end
-spec splice_value_into(term(), proplists:proplist(), list(), list()) -> list().
splice_value_into(Field, Plist, InList1, InList2) ->
  {_, Value} = proplists:lookup(Field, Plist),
  splice_into(Value, InList1, InList2).

%% @doc
%% Test a proplist to see if a value is included
%% @end
-spec value_is_not_included(term(), proplists:proplist(), list()) -> boolean().
value_is_not_included(Field, Plist, InList) ->
  {_, Value} = proplists:lookup(Field, Plist),
  not lists:member(Value, InList).

%% @equiv not regex_matches(Binary, Regex).
regex_does_not_match(Binary, Regex) -> not regex_matches(Binary, Regex).

%% @doc
%% Test to see if regex string (from re module) matches binary
%% @end
regex_matches(Binary, Regex) ->
  case re:run(Binary, Regex) of
    {match, _Captured} -> true;
    nomatch -> false
  end.
