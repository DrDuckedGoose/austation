/*
    Copying some of obj/item/paper code

*/
#define MAX_EXPRESSION_LENGTH 30
#define MAX_REACH 50
#define MAX_CALLBACK 10

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

    var/scroll_text = "" //what's written inside, the speeeeeells
    var/cursor = 1 //Psycho initializing
    var/in_memory[2] //THe one value you get to keep

/obj/item/scroll/Initialize()
    ..()
    pixel_y = rand(-8, 8)
    pixel_x = rand(-9, 9)

    scroll_text = @"+<<[>>-]>>[>$l<-]$r>$t$f"

/obj/item/scroll/proc/compile(mob/user, atom/target, var/scroll_text)

    var/callback //Used for lopping expressions
    var/callback_count = 0

    var/stack[10]
    var/tongue = "" //What expression is currently being ran
    var/count = 1

    stack[in_memory[1]] = in_memory[2]

    while(tongue != "/F"||count < 100)
        tongue = scroll_text[count]
        //to_chat(user, tongue)

        switch(tongue)
            //Regular expressions
            if(@">")
                if(cursor < 30)cursor++

            if(@"<")
                if(cursor > 1)cursor--

            if(@"+")
                if(stack[cursor] < MAX_REACH)stack[cursor]++

            if(@"-")
                if(stack[cursor] > MAX_REACH*-1)stack[cursor]--

            if(@"[")
                callback = count

            if(@"]")
                if(callback)
                    //wait call here
                    if(stack[cursor] && callback_count < MAX_CALLBACK) 
                        count = callback
                        callback_count++
            if(@"^")
                if(istype(stack[cursor], /mob/living/carbon/))
                    stack[cursor] = get_turf(stack[cursor])

            if(@"*")
                in_memory[1] = cursor
                in_memory[2] = stack[cursor]

            if(@"!")
                in_memory[1] = cursor
                in_memory[2] = 0

            //Tricks, the real soup
            if(@"$")
                tongue = scroll_text[count+1]
                count++
                switch(tongue)
                    if("f")//Finish spell
                        tongue = "/F" //Finish command

                    if("s")//Output a message to a target. Expressively for IG debugging spells.
                        var/atom/who = stack[cursor-1]
                        var/message = stack[cursor]
                        to_chat(who, message)

                    if("r")//Reflect, adds user to the stack
                        stack[cursor] = user

                    if("p")//Moves a source away from where the player is facing
                        var/atom/who = stack[cursor-1]
                        var/strength = stack[cursor]
                        var/direction
                        if(who == user)direction = user.dir
                        else direction = get_dir(user, who)

                        var/atom/movable/AM = who
                        AM.throw_at(get_edge_target_turf(user, direction), strength, 1)

                    if("q")//Moves a source towards from where the player is facing
                        var/atom/who = stack[cursor-1]
                        var/strength = stack[cursor]
                        var/direction
                        if(who == user)direction = user.dir
                        else direction = get_dir(who, user)

                        var/atom/movable/AM = who
                        AM.throw_at(get_edge_target_turf(user, direction), strength, 1)

                    if("l")//Where you're looking, aka clicking
                        stack[cursor] = target

                    if("d")//distance between two points
                        var/loc1 = stack[cursor-1]
                        var/loc2 = stack[cursor]

                        stack[cursor+1] = get_dist(loc1, loc2)
                    
                    if("t")//teleport
                        var/atom/who = stack[cursor-1]
                        var/destination = stack[cursor]

                        var/atom/movable/AM = who
                        do_teleport(AM, destination)

                    if("h")//zap - harmless stun
                        var/mob/living/carbon/who = stack[cursor]
                        who.electrocute_act(1, user, 1, 1)

        count++

    in_memory = stack[-1]
    return 1

/obj/item/scroll/attack_self(mob/user)
    cursor = 1
    compile(user, user, scroll_text)

/obj/item/scroll/afterattack(atom/target, mob/user, proximity)
    ..()

    cursor = 1
    compile(user, target, scroll_text)
        
