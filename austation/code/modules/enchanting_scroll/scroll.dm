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
    var/cursor = 1//Psycho initializing

/obj/item/scroll/Initialize()
    ..()
    pixel_y = rand(-8, 8)
    pixel_x = rand(-9, 9)

    scroll_text = @"+++[>$r>+++$p---<<-]$f"

/obj/item/scroll/proc/compile(mob/user, mob/target, var/scroll_text)

    var/callback //Used for lopping expressions
    var/callback_count = 0

    var/stack[10]
    var/tongue = "" //What expression is currently being added to the list.
    var/count = 1
    while(tongue != "/F"||count < 100)
        tongue = scroll_text[count]
        //to_chat(user, tongue)

        switch(tongue)
            //Regular expressions
            if(@">")
                if(cursor < 30)cursor++//Using ++ with lists doesn't go down well

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

            //Tricks
            if(@"$")
                to_chat(user, "Entered Tricks")
                tongue = scroll_text[count+1]
                count++
                switch(tongue)
                    if("f")//Finish spell
                        to_chat(user, "Entered finish")
                        tongue = "/F" //Finish command

                    if("s")//Output a message to a target. Expressively for IG debugging spells.
                        var/atom/who = stack[cursor-1]
                        var/message = stack[cursor]
                        to_chat(who, message)

                    if("r")//Reflect, adds user to the stack
                        stack[cursor] = user

                    if("p")//Moves a source by the force of a value 
                        to_chat(user, "Entered push")
                        var/atom/who = stack[cursor-1]
                        var/strength = stack[cursor]
                        var/direction
                        if(who == user)direction = user.dir
                        else direction = get_dir(user, who)

                        step(who, direction, strength)

                    if("l")//look, 
                        stack[cursor] = target

        count++

    return 1

/obj/item/scroll/attack_self(mob/user)
    cursor = 1
    compile(user, user, scroll_text)

/obj/item/scroll/afterattack(atom/target, mob/user, proximity)
    ..()

    cursor = 1
    compile(user, target, scroll_text)
        
