%%%-------------------------------------------------------------------
%%% @author yaohong
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 十一月 2016 14:28
%%%-------------------------------------------------------------------
-module(hh_mj_util).
-author("yaohong").
-include("hh_mj.hrl").
-include("../qp_type.hrl").
-include("../../deps/file_log/include/file_log.hrl").
%% API
-export([generate_main_logic/1, print/1]).

%%生成hh_main_logic
generate_main_logic(Bin) ->
	<<
		PaiPool:120/binary, PoolHeadReadIndex:?BIG_UINT8, PoolTailReadIndex:?BIG_UINT8,
		Seat0:43/binary, Seat1:43/binary,Seat2:43/binary,Seat3:43/binary,
		BrankerNumber:?BIG_UINT8,SpecialData:8/binary, HuData:5/binary,
		ChuPaiSeatNum:?BIG_INT8, ChuPaiValue:?BIG_UINT8,
		OldData:5/binary, NextData:4/binary,StateFlag:?BIG_UINT8,ErrorFlag:?BIG_UINT8,
		HupaiResult:5/binary, ErrorLogData:256/binary
	>> = Bin,
	ValidPoolList =
		if
			PoolHeadReadIndex =:= PoolTailReadIndex andalso PoolHeadReadIndex =:= 0 ->
				[];
			true ->
				HeadLen = PoolHeadReadIndex,
				TailLen = ?HH_POOL_COUNT - 1 - PoolTailReadIndex,
				ValidPoolLen = ?HH_POOL_COUNT - HeadLen - TailLen,
				<<_:HeadLen/binary, ValidPool:ValidPoolLen/binary, _:TailLen/binary>> = PaiPool,
				binary_to_list(ValidPool)
		end,
	#hh_main_logic{
		pool = ValidPoolList,
		seat0 = generate_seat(Seat0),
		seat1 = generate_seat(Seat1),
		seat2 = generate_seat(Seat2),
		seat3 = generate_seat(Seat3),
		banker_seat_number = BrankerNumber,
		special = generage_special(SpecialData),
		hu = generage_hu(HuData),
		chupai_seatnumber = ChuPaiSeatNum,
		chupai_value = ChuPaiValue,
		old = generage_old(OldData),
		next = generage_next(NextData),
		state_flag = StateFlag,
		error_flag = ErrorFlag,
		hupai_result = generage_hupai_result(HupaiResult),
		error_log = generage_error_log(ErrorLogData)
	}.


%%根据二进制数据生成seat
generate_seat(Bin) ->
	<<
		C0:2/binary, C1:2/binary, C2:2/binary, C3:2/binary,
		P0:2/binary, P1:2/binary, P2:2/binary, P3:2/binary,
		G0:3/binary, G1:3/binary, G2:3/binary, G3:3/binary,
		PaiBin:14/binary, WriteIndex:?BIG_UINT8
	>> = Bin,
	Chi = generate_seat_chi_list(generate_seat_chi(C0), generate_seat_chi(C1), generate_seat_chi(C2), generate_seat_chi(C3)),
	Peng = generate_seat_peng_list(generate_seat_peng(P0), generate_seat_peng(P1), generate_seat_peng(P2), generate_seat_peng(P3)),
	Gang = generate_seat_gang_list(generate_seat_gang(G0), generate_seat_gang(G1), generate_seat_gang(G2), generate_seat_gang(G3)),
	ValidPaiLen = WriteIndex,
	<<ValidPoolBin:ValidPaiLen/binary, _/binary>> = PaiBin,
	ValidPoolList = binary_to_list(ValidPoolBin),
	#hh_seat {
		chi = Chi,
		peng = Peng,
		gang = Gang,
		pai = ValidPoolList
	}.

generate_seat_chi(Bin) when is_binary(Bin) ->
	<<Pai:?BIG_UINT8, Type:?BIG_UINT8>> = Bin,
	#hh_seat_chi{pai = Pai, type = Type}.

generate_seat_peng(Bin) when is_binary(Bin) ->
	<<Pai:?BIG_UINT8, SeatNumber:?BIG_INT8>> = Bin,
	#hh_seat_peng{pai = Pai, seat_number = SeatNumber}.

generate_seat_gang(Bin) when is_binary(Bin) ->
	<<Pai:?BIG_UINT8, Type:?BIG_UINT8, SeatNumber:?BIG_INT8>> = Bin,
	#hh_seat_gang{pai = Pai, type = Type, seat_number = SeatNumber}.


generate_seat_chi_list(#hh_seat_chi{pai = 0}, _, _, _) -> [];
generate_seat_chi_list(P1, #hh_seat_chi{pai = 0}, _, _) -> [P1];
generate_seat_chi_list(P1,P2, #hh_seat_chi{pai = 0}, _) -> [P1, P2];
generate_seat_chi_list(P1,P2, P3, #hh_seat_chi{pai = 0}) -> [P1, P2, P3];
generate_seat_chi_list(P1,P2, P3, P4) -> [P1, P2, P3, P4].

generate_seat_peng_list(#hh_seat_peng{pai = 0}, _, _, _) -> [];
generate_seat_peng_list(P1, #hh_seat_peng{pai = 0}, _, _) -> [P1];
generate_seat_peng_list(P1,P2, #hh_seat_peng{pai = 0}, _) -> [P1, P2];
generate_seat_peng_list(P1,P2, P3, #hh_seat_peng{pai = 0}) -> [P1, P2, P3];
generate_seat_peng_list(P1,P2, P3, P4) -> [P1, P2, P3, P4].

generate_seat_gang_list(#hh_seat_gang{pai = 0}, _, _, _) -> [];
generate_seat_gang_list(P1, #hh_seat_gang{pai = 0}, _, _) -> [P1];
generate_seat_gang_list(P1,P2, #hh_seat_gang{pai = 0}, _) -> [P1, P2];
generate_seat_gang_list(P1,P2, P3, #hh_seat_gang{pai = 0}) -> [P1, P2, P3];
generate_seat_gang_list(P1,P2, P3, P4) -> [P1, P2, P3, P4].


generage_special(SpecialData) ->
	<<
		Oper0SeatNum:?BIG_UINT8,Oper0Flag:?BIG_UINT8,
		Oper1SeatNum:?BIG_UINT8,Oper1Flag:?BIG_UINT8,
		Oper2SeatNum:?BIG_UINT8,Oper2Flag:?BIG_UINT8,
		OperCount:?BIG_UINT8, OperIndex:?BIG_UINT8
	>> = SpecialData,
	L1 = [{Oper0SeatNum, Oper0Flag},{Oper1SeatNum, Oper1Flag},{Oper2SeatNum, Oper2Flag}],
	{VaildQueue, _} = lists:split(OperCount, L1),
	#hh_special {
		oper_queue = VaildQueue,
		oper_index = OperIndex
	}.

generage_hu(HuData) ->
	<<
		SeatNum0:?BIG_UINT8,SeatNum1:?BIG_UINT8, SeatNum3:?BIG_UINT8,
		OperCount:?BIG_UINT8, OperIndex:?BIG_UINT8
	>> = HuData,
	L1 = [SeatNum0,SeatNum1,SeatNum3],
	{VaildQueue, _} = lists:split(OperCount, L1),
	#hh_hu {
		queue = VaildQueue,
		index = OperIndex
	}.

generage_old(OldData) ->
	<<
		SeatNumber:?BIG_INT8,Flag:?BIG_UINT8,
		Type:?BIG_UINT8, Value1:?BIG_UINT8,
		Value2:?BIG_UINT8
	>> = OldData,
	#hh_old_oper{
		seat_number = SeatNumber,
		flag = Flag,
		type = Type,
		value1 = Value1,
		value2 = Value2
	}.

generage_next(NextData) ->
	<<
		SeatNumber:?BIG_INT8,Flag:?BIG_UINT8,
		Value1:?BIG_UINT8, Value2:?BIG_UINT8
	>> = NextData,
	#hh_next_oper{
		seat_number = SeatNumber,
		flag = Flag,
		value1 = Value1,
		value2 = Value2
	}.

generage_hupai_result(Data) ->
	<<
		SeatNumber:?BIG_INT8, Value:?BIG_UINT8,
		Type:?BIG_UINT8, Level:?BIG_UINT8, FangpaoSeatNumber:?BIG_INT8
	>> = Data,
	#hh_hupai_result{
		seat_number = SeatNumber,
		value = Value,
		type = Type,
		level = Level,
		fangpao_set_number = FangpaoSeatNumber
	}.

str_pai(0) -> "(0)";
str_pai(Pai)  -> str_pai(pai_type(Pai), pai_value(Pai)) ++ "(" ++ integer_to_list(Pai) ++ ")".

str_pai(1, V) -> integer_to_list(V) ++ "-wan";
str_pai(2, V) -> integer_to_list(V) ++ "-tiao";
str_pai(3, V) -> integer_to_list(V) ++ "-tong";
str_pai(4, 1) -> "dong-feng";
str_pai(4, 2) -> "nan-feng";
str_pai(4, 3) -> "xi-feng";
str_pai(4, 4) -> "bei-feng";
str_pai(5, 1) -> "hongzhong";
str_pai(5, 2) -> "facai";
str_pai(5, 3) -> "baiban".

str_oper(0) -> "none(0)";
str_oper(1) -> "chi(1)";
str_oper(2) -> "peng(2)";
str_oper(4) -> "gang(4)";
str_oper(8) -> "hu(8)";
str_oper(16) -> "chu(16)";
str_oper(32) -> "guo(32)".

str_oper_flag(OperFlag) ->
	str_oper_flag([1,2,4,8,16,32], OperFlag, "").
str_oper_flag([], _, Str) -> Str;
str_oper_flag([Oper|T], OperFlag, Str) ->
	case Oper band OperFlag of
		0 -> str_oper_flag(T, OperFlag, Str) ;
		_ -> str_oper_flag(T, OperFlag, Str ++"," ++ str_oper(Oper))
	end.



pai_type(Pai) -> Pai bsr 4.
pai_value(Pai) -> Pai band 2#00001111.

generage_error_log(LogData) ->
	<<
		ErrorBuff:255/binary,LogLen:?BIG_UINT8
	>> = LogData,
	{ValidLog , _} = lists:split(LogLen, binary_to_list(ErrorBuff)),
	#hh_error_log{
		log = ValidLog
	}.



print(Logic) when is_record(Logic, hh_main_logic) ->
	Seat0 = Logic#hh_main_logic.seat0,
	Seat1 = Logic#hh_main_logic.seat1,
	Seat2 = Logic#hh_main_logic.seat2,
	Seat3 = Logic#hh_main_logic.seat3,
	Special = Logic#hh_main_logic.special,
	Hu = Logic#hh_main_logic.hu,
	Old = Logic#hh_main_logic.old,
	Next = Logic#hh_main_logic.next,
	Result = Logic#hh_main_logic.hupai_result,
	?FILE_LOG_DEBUG(
		"--------start print--------\n"
		"pai_pool:~p ~p\n"
		"seat0:\n"
		"	chi:~p\n"
		"	peng:~p\n"
		"	gang:~p\n"
		"	pai:~p ~p\n"
		"seat1:\n"
		"	chi:~p\n"
		"	peng:~p\n"
		"	gang:~p\n"
		"	pai:~p ~p\n"
		"seat2:\n"
		"	chi:~p\n"
		"	peng:~p\n"
		"	gang:~p\n"
		"	pai:~p ~p\n"
		"seat3:\n"
		"	chi:~p\n"
		"	peng:~p\n"
		"	gang:~p\n"
		"	pai:~p ~p\n"
		"banker_seat_number:~p\n"
		"special:\n"
		"	oper_queue:~p\n"
		"	oper_index:~p\n"
		"hu:\n"
		"	queue:~p\n"
		"	index:~p\n"
		"chupai_seatnumber:~p\n"
		"chupai_value:~p\n"
		"old:\n"
		"	seat_number:~p\n"
		"	flag:~p\n"
		"	type:~p\n"
		"	value1:~p\n"
		"	value2:~p\n"
		"next:\n"
		"	seat_number:~p\n"
		"	flag:~p\n"
		"	value1:~p\n"
		"	value2:~p\n"
		"state_flag:~p\n"
		"error_flag:~p\n"
		"hupai_result:\n"
		"	seat_number:~p\n"
		"	value:~p\n"
		"	type:~p\n"
		"   level:~p\n"
		"	fangpao_set_number:~p\n"
		"error_log:~p\n"
		,
		[
			length(Logic#hh_main_logic.pool),
			[str_pai(Pai) || Pai <- Logic#hh_main_logic.pool],
			[{str_pai(Pai), Type} || #hh_seat_chi{pai = Pai,type = Type} <- Seat0#hh_seat.chi],
			[{str_pai(Pai),  SeatNumber} || #hh_seat_peng{pai = Pai, seat_number = SeatNumber} <- Seat0#hh_seat.peng],
			[{str_pai(Pai), Type, SeatNumber} || #hh_seat_gang{pai = Pai, type = Type, seat_number = SeatNumber} <- Seat0#hh_seat.gang],
			length(Seat0#hh_seat.pai),
			[str_pai(Pai) || Pai <- Seat0#hh_seat.pai],

			[{str_pai(Pai), Type} || #hh_seat_chi{pai = Pai,type = Type} <- Seat1#hh_seat.chi],
			[{str_pai(Pai),  SeatNumber} || #hh_seat_peng{pai = Pai, seat_number = SeatNumber} <- Seat1#hh_seat.peng],
			[{str_pai(Pai), Type, SeatNumber} || #hh_seat_gang{pai = Pai, type = Type, seat_number = SeatNumber} <- Seat1#hh_seat.gang],
			length(Seat1#hh_seat.pai),
			[str_pai(Pai) || Pai <- Seat1#hh_seat.pai],

			[{str_pai(Pai), Type} || #hh_seat_chi{pai = Pai,type = Type}  <- Seat2#hh_seat.chi],
			[{str_pai(Pai),  SeatNumber} || #hh_seat_peng{pai = Pai, seat_number = SeatNumber}  <- Seat2#hh_seat.peng],
			[{str_pai(Pai), Type, SeatNumber} || #hh_seat_gang{pai = Pai, type = Type, seat_number = SeatNumber} <- Seat2#hh_seat.gang],
			length(Seat2#hh_seat.pai),
			[str_pai(Pai) || Pai <- Seat2#hh_seat.pai],

			[{str_pai(Pai), Type} || #hh_seat_chi{pai = Pai,type = Type}  <- Seat3#hh_seat.chi],
			[{str_pai(Pai),  SeatNumber} || #hh_seat_peng{pai = Pai, seat_number = SeatNumber}   <- Seat3#hh_seat.peng],
			[{str_pai(Pai), Type, SeatNumber} || #hh_seat_gang{pai = Pai, type = Type, seat_number = SeatNumber} <- Seat3#hh_seat.gang],
			length(Seat3#hh_seat.pai),
			[str_pai(Pai) || Pai <- Seat3#hh_seat.pai],

			Logic#hh_main_logic.banker_seat_number,

			[{SeatNumber, str_oper_flag(OperFlag)} || {SeatNumber, OperFlag} <- Special#hh_special.oper_queue],
			Special#hh_special.oper_index,

			[SeatNumber || SeatNumber <- Hu#hh_hu.queue],
			Hu#hh_hu.index,

			Logic#hh_main_logic.chupai_seatnumber,
			str_pai(Logic#hh_main_logic.chupai_value),


			Old#hh_old_oper.seat_number,
			str_oper_flag(Old#hh_old_oper.flag),
			str_oper(Old#hh_old_oper.type),
			str_pai(Old#hh_old_oper.value1),
			Old#hh_old_oper.value2,

			Next#hh_next_oper.seat_number,
			str_oper_flag(Next#hh_next_oper.flag),
			str_pai(Next#hh_next_oper.value1),
			str_pai(Next#hh_next_oper.value2),


			Logic#hh_main_logic.state_flag,
			Logic#hh_main_logic.error_flag,

			Result#hh_hupai_result.seat_number,
			str_pai(Result#hh_hupai_result.value),
			Result#hh_hupai_result.type,
			Result#hh_hupai_result.level,
			Result#hh_hupai_result.fangpao_set_number,

			Logic#hh_main_logic.error_log#hh_error_log.log
		]
	),
	ok.



