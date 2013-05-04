open Printf
open Set
open Cil
open Dlgraph
open Dlthread
open List

module Sm = Map.Make(String)
module Ss = Set.Make(String)


class locksetHelper = 
	object (self)
	
	val mutable acq_cache = Sm.empty
	val mutable hold_cache = Sm.empty
	val mutable lockset = Ss.empty
	
	method constr_acqstr context lockset opr acq = 
		let  acqstr = String.concat "," (Ss.elements lockset)
		in let acqstr = String.concat ";" [context.fname;acqstr;opr;acq]
		in acqstr
		
	method is_lock_opr opr = if opr="pthread_mutex_lock" || opr = "pthread_mutex_trylock" then true else false
	
	method ml_il context il locksetg = 
		match il with
		Call(_,Lval(lvar),AddrOf(arg)::lst,_)::xil ->
			let opr,acq = 
			begin
				match ((fst lvar),(fst arg)) with 
				| (Var(varinfo),Var(arginfo)) -> varinfo.vname,arginfo.vname
				| _ -> "",""
			end
			in
			let locksetg = (* acq vertex -->  hold cache *)
			begin		
				
				if (self#is_lock_opr opr) && not (Ss.is_empty lockset) then
					begin	
						let acqstr = self#constr_acqstr context lockset opr acq in
						if Sm.mem acq hold_cache then							
							let ss = Sm.find acq hold_cache in
							let () = Ss.iter (fun s -> locksetg#add_str_edge acqstr s;()) ss
							in locksetg
						else locksetg 
					end
				else locksetg
			end
			in
			let locksetg = (* hold vertices <-- acq cache *)
			begin
				if (self#is_lock_opr opr) && not (Ss.is_empty lockset) then 
					begin
						Ss.iter 
							(fun hold -> 
								let acq_strs = if Sm.mem hold acq_cache then Sm.find hold acq_cache else Ss.empty
								in 
								Ss.iter (fun acq_str -> locksetg#add_str_edge acq_str (self#constr_acqstr context lockset opr acq) ; ()) acq_strs
							) 
						lockset ;
					locksetg;
					end
					
				else locksetg 
			end
			in
			let () = (* update acq_cache, hold_cache *)
				begin
					if (self#is_lock_opr opr) && not (Ss.is_empty lockset) then	
						begin (* update acq_cache *)
						if Sm.mem acq acq_cache then 
							begin
							acq_cache <- Sm.add acq (Ss.add (self#constr_acqstr context lockset opr acq) (Sm.find acq acq_cache)) acq_cache;
							(* printf "%s --> " acq;
							Ss.iter (fun c-> printf "%s | " c) (Sm.find acq acq_cache); *)
							end
						else 
							let ns = Ss.add (self#constr_acqstr context lockset opr acq) (Ss.empty) in 
							acq_cache <- Sm.add acq ns acq_cache ;
							
						Ss.iter (* update hold_cache *)
							begin
								fun hold -> 
									begin
										if Sm.mem hold hold_cache then
											hold_cache <- Sm.add hold (Ss.add (self#constr_acqstr context lockset opr acq) (Sm.find hold hold_cache)) hold_cache
										else 
											let ns = Ss.add (self#constr_acqstr context lockset opr acq) (Ss.empty) in 
											hold_cache <- Sm.add hold ns hold_cache;
									end
							end lockset
						end					
				end
			in
			let () = (* update lockset *)
				if (self#is_lock_opr opr) then	lockset<-Ss.add acq lockset		
				else if opr = "pthread_mutex_unlock" then lockset<-Ss.remove acq lockset						
			in
			self#ml_il context xil locksetg
		| _::xil -> self#ml_il context xil locksetg
		| _-> locksetg
		

	method ml_if context tpath fpath locksetg = 
		let old_lockset = lockset in
		let locksetg = 
			List.fold_left 
			begin
				fun locksetg elt ->  
				match elt.skind with
				| Instr(il) -> self#ml_il context il locksetg
				| If(_,tp,fp,_) -> self#ml_if context tp fp locksetg
				| _ -> locksetg 
			end locksetg tpath.bstmts  
		in 
		lockset <- old_lockset;
		let locksetg = 
			List.fold_left
			begin
				fun locksetg elt -> 
				match elt.skind with
				| Instr(il) -> self#ml_il context il locksetg
				| If(_,tp,fp,_) -> self#ml_if context tp fp locksetg
				| _ -> locksetg 				
			end locksetg fpath.bstmts
		in locksetg
	
	method marklockset context stmts locksetg = 
		match stmts with
		s::xstmts -> 
			let locksetg = 
				begin
					match s.skind with
					| Instr(il) -> self#ml_il context il locksetg
					| If(_,tp,fp,_) -> self#ml_if context tp fp locksetg
					| Loop(blk,_,_,_) -> self#marklockset context blk.bstmts locksetg
					| _ -> locksetg
				end
			in (self)#marklockset context xstmts locksetg
		| _ -> locksetg
	
	method marklockset_ts ts tfm = 
		let locksetg = new lockGraph in
		Ts.fold 
			begin 
				fun elt locksetg
					-> 
					let fundec = Sm.find elt.fname tfm in 
						self#marklockset elt fundec.sbody.bstmts locksetg
			end ts locksetg
end 			


let marklockset_tss tss tfm = 
	let graphList = [] in
	Tss.fold 
		begin
			fun ts graphList -> ((new locksetHelper)#marklockset_ts ts tfm) :: graphList
		end tss graphList
		