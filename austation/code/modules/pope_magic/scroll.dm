/*
   
*/
#define MAX_EXPRESSION_LENGTH 100 //Max symbols a spell can have, this includes both parts of a trick, $ & A. Generally to stop OP complex spells. 
#define MAX_REACH 50 //Max distance a spell can reach, mainly stops people teleporting too far
#define MAX_INTEGER 100 //Max number expression. As of writing, I don;t think big numbers can be exploited but, I'm not taking that risk.
#define MAX_CALLBACK 9 //Stops loops from being infinite, pretty obvious why that's necesary.


/obj/item/scroll
    name = "Enchanting Scroll"
    max_integrity = 100
    gender = NEUTER
    icon = 'icons/obj/bureaucracy.dmi'
    icon_state = "paper"
    item_state = "paper"
    custom_fire_overlay = "paper_onfire_overlay"
    throwforce = 0
    w_class = WEIGHT_CLASS_TINY
    throw_range = 1
    throw_speed = 1
    pressure_resistance = 0
    resistance_flags = FLAMMABLE
    max_integrity = 150
    color = "white"

    var/scroll_text = "" //what's written inside, the spell. Expressions & tricks
    var/atom/in_memory[2] //Which stack to save
    var/GREATER_SPELLS = FALSE //Grand virgin shit

/obj/item/scroll/Initialize()
    ..()
    pixel_y = rand(-8, 8)
    pixel_x = rand(-9, 9)

/obj/item/scroll/proc/compile(mob/user, atom/target, var/scroll_text)
    //Variables set here are done so that they can be reset every call

    var/callback[MAX_CALLBACK] //Which loop/bracket is being discussed
    var/callback_cursor = 1 //Used for navigating callbacks ^
    var/callback_count[MAX_CALLBACK] //Keep track of how many times a loop has recalled, should never exceed MAX_CALLBACK

    var/stack[10]//Temporary memory stack
    var/cursor = 1//used for navigating stack ^

    var/tongue = "" //What part of the spell is being read
    var/count = 1 //Essentially acts as a cursor

    if(in_memory[2])stack[in_memory[1]] = in_memory[2] //Load memory into saved stack

    while(tongue||count < MAX_EXPRESSION_LENGTH)
        tongue = scroll_text[count]

        switch(tongue)
            //Regular expressions
            if(@">")//Move to right stack
                if(cursor < 30)cursor++

            if(@"<")//Move to left stack
                if(cursor > 1)cursor--

            if(@"+")//Iterate stack foward
                if(stack[cursor] < MAX_INTEGER) stack[cursor]++

            if(@"-")//Iterate stack backwards
                if(stack[cursor] > MAX_INTEGER*-1) stack[cursor]--

            if(@"[")//Jump to next apppropriate "]" if current stack is null
                if(stack[cursor])
                    if(!callback[callback_cursor])
                        callback[callback_cursor] = count
                    else if(count != callback[callback_cursor])   
                        callback_cursor++
                        callback[callback_cursor] = count
                else    
                    while(tongue != @"]")
                        count++
                        tongue = scroll_text[count]

            if(@"]")//Jump BACK to next appropriate "[" if stack isn't null
                if(stack[cursor])
                    if(callback[callback_cursor] && callback_count[callback_cursor] < MAX_CALLBACK)
                        count = callback[callback_cursor]
                        callback_count[callback_cursor]++
                    else    
                        callback[callback_cursor] = null
                        callback_count[callback_cursor] = null
                        callback_cursor--
                else 
                    callback[callback_cursor] = null
                    callback_count[callback_cursor] = null
                    callback_cursor--

            if(@"*")//Save current stack to memory
                in_memory[1] = cursor
                in_memory[2] = stack[cursor]

            if(@"!")//Clear current stack
                stack[cursor] = null

            if(@"=")//Load memory into current stack
                stack[cursor] = in_memory[2]

            //Tricks, exciting!
            if(@"$")
                tongue = scroll_text[count+1]
                count++
                switch(tongue)
                    if("f")//Finish spell, use to save on cooldown
                        tongue = "/F" //Finish command

                    if("s")//Output current stack to previous stack
                        var/atom/who = stack[cursor-1]
                        var/message = stack[cursor]
                        to_chat(who, message)

                    if("r")//Add user to current stack
                        stack[cursor] = user

                    if("p")//Push previous stack by current stack
                        var/atom/who = stack[cursor-1]
                        var/strength = stack[cursor]
                        var/direction
                        if(who == user)direction = user.dir
                        else direction = get_dir(user, who)

                        var/atom/movable/AM = who
                        AM.throw_at(get_edge_target_turf(user, direction), strength, 1)

                    if("q")//Pull previous stack by current stack
                        var/atom/who = stack[cursor-1]
                        var/strength = stack[cursor]
                        var/direction
                        if(who == user)direction = user.dir
                        else direction = get_dir(who, user)

                        var/atom/movable/AM = who
                        AM.throw_at(get_edge_target_turf(user, direction), strength, 1)

                    if("l")//Set target to current stack, where, who or what you're clicking
                        stack[cursor] = target

                    if("d")//Set previous stack to the distance between the current stack and the previous stack, sets the next current stack to null
                        var/loc1 = stack[cursor-1]
                        var/loc2 = stack[cursor]

                        stack[cursor-1] = get_dist(loc1, loc2)
                        stack[cursor] = null
                    
                    if("t")//Teleport previous stack to current stack
                        var/atom/who = stack[cursor-1]
                        var/destination = stack[cursor]
                        var/atom/movable/AM = who
                        do_teleport(AM, destination)

                    if("h")//Zap current stack
                        var/mob/living/carbon/who = stack[cursor]
                        who.Paralyze(15)

                    if("i")//Interact with current stack
                        var/obj/what = stack[cursor]
                        what.attack_self_tk(user)

                    if("b")//Break the current stack down into an xyz at the current, next and next next stack, respectively. 
                        var/turf/where = get_turf(stack[cursor])
                        stack[cursor] = where.x
                        stack[cursor+1] = where.y
                        stack[cursor+2] = where.z

                    if("c")//Collapse the current stack from an xyz(SEE "b")
                        var/turf/where = locate(stack[cursor], stack[cursor+1], stack[cursor+2])
                        stack[cursor] = where

                        stack[cursor+1] = null
                        stack[cursor+2] = null
                        
        count++
    return 1

/obj/item/scroll/attack_self(mob/user)
    compile(user, user, scroll_text)

/obj/item/scroll/afterattack(atom/target, mob/user, proximity)
    ..()
    compile(user, target, scroll_text)

/obj/item/scroll/can_interact(mob/user)
	if(in_contents_of(/obj/machinery/door/airlock))
		return TRUE
	return ..()
