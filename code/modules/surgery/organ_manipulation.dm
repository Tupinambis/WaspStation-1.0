/datum/surgery/organ_manipulation
	name = "Organ manipulation"
	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD)
	requires_real_bodypart = 1
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/saw,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/incise,
		/datum/surgery_step/manipulate_organs,
		//there should be bone fixing
		/datum/surgery_step/close
		)

/datum/surgery/organ_manipulation/soft
	possible_locs = list(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/incise,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/close
		)

/datum/surgery/organ_manipulation/alien
	name = "Alien organ manipulation"
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	target_mobtypes = list(/mob/living/carbon/alien/humanoid)
	steps = list(
		/datum/surgery_step/saw,
		/datum/surgery_step/incise,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/saw,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/close
		)

/datum/surgery/organ_manipulation/mechanic
	name = "Prosthesis organ manipulation"
	possible_locs = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ROBOTIC
	lying_required = FALSE
	self_operable = TRUE
	steps = list(
		/datum/surgery_step/mechanic_open,
		/datum/surgery_step/open_hatch,
		/datum/surgery_step/mechanic_unwrench,
		/datum/surgery_step/prepare_electronics,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/mechanic_wrench,
		/datum/surgery_step/mechanic_close
		)

/datum/surgery/organ_manipulation/mechanic/soft
	possible_locs = list(BODY_ZONE_PRECISE_GROIN, BODY_ZONE_PRECISE_EYES, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	steps = list(
		/datum/surgery_step/mechanic_open,
		/datum/surgery_step/open_hatch,
		/datum/surgery_step/prepare_electronics,
		/datum/surgery_step/manipulate_organs,
		/datum/surgery_step/mechanic_close
		)

/datum/surgery_step/manipulate_organs
	time = 64
	name = "manipulate organs"
	repeatable = TRUE
	implements = list(/obj/item/organ = 100, /obj/item/organ_storage = 100)
	var/implements_extract = list(TOOL_HEMOSTAT = 100, TOOL_CROWBAR = 55, /obj/item/kitchen/fork = 35)
	var/current_type
	var/obj/item/organ/I = null

/datum/surgery_step/manipulate_organs/New()
	..()
	implements = implements + implements_extract

/datum/surgery_step/manipulate_organs/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	I = null
	if(istype(tool, /obj/item/organ_storage))
		if(!tool.contents.len)
			to_chat(user, "<span class='warning'>There is nothing inside [tool]!</span>")
			return -1
		I = tool.contents[1]
		if(!isorgan(I))
			to_chat(user, "<span class='warning'>You cannot put [I] into [target]'s [parse_zone(target_zone)]!</span>")
			return -1
		tool = I
	if(isorgan(tool))
		current_type = "insert"
		I = tool
		if(target_zone != I.zone || target.getorganslot(I.slot))
			to_chat(user, "<span class='warning'>There is no room for [I] in [target]'s [parse_zone(target_zone)]!</span>")
			return -1
		var/obj/item/organ/meatslab = tool
		if(!meatslab.useable)
			to_chat(user, "<span class='warning'>[I] seems to have been chewed on, you can't use this!</span>")
			return -1
		display_results(user, target, "<span class='notice'>You begin to insert [tool] into [target]'s [parse_zone(target_zone)]...</span>",
			"<span class='notice'>[user] begins to insert [tool] into [target]'s [parse_zone(target_zone)].</span>",
			"<span class='notice'>[user] begins to insert something into [target]'s [parse_zone(target_zone)].</span>")

	//WaspStation Begin - IPCs

	if(istype(tool, /obj/item/mmi))//this whole thing is only used for robotic surgery in organ_mani_robotic.dm :*
		current_type = "posibrain"
		var/obj/item/bodypart/affected = target.get_bodypart(check_zone(target_zone))
		if(!affected)
			return -1
		if(affected.status != ORGAN_ROBOTIC)
			to_chat(user, "<span class='notice'>You can't put [tool] into a meat enclosure!</span>")
			return -1
		if(!isipc(target))
			to_chat(user, "<span class='notice'>[target] does not have the proper connectors to interface with [tool].</span>")
			return -1
		if(target_zone != "chest")
			to_chat(user, "<span class='notice'>You have to install [tool] in [target]'s chest!</span>")
			return -1
		if(target.internal_organs_slot[ORGAN_SLOT_BRAIN])
			to_chat(user, "<span class='notice'>[target] already has a brain! You'd rather not find out what would happen with two in there.</span>")
			return -1
		var/obj/item/mmi/P = tool
		if(!istype(P))
			return -1
		if(!P.brainmob || !P.brainmob.client)
			to_chat(user, "<span class='notice'>[tool] has no life in it, this would be pointless!</span>")
			return -1
		var/obj/item/organ/meatslab = tool
		if(!meatslab.useable)
			to_chat(user, "<span class='warning'>[I] seems to have been chewed on, you can't use this!</span>")
			return -1

	//WaspStation End

	else if(implement_type in implements_extract)
		current_type = "extract"
		var/list/organs = target.getorganszone(target_zone)

		var/mob/living/simple_animal/borer/B = target.has_brain_worms()		//Wasp Begin - Borers
		if(target.has_brain_worms())
			user.visible_message("[user] begins to extract [B] from [target]'s [parse_zone(target_zone)].",
					"<span class='notice'>You begin to extract [B] from [target]'s [parse_zone(target_zone)]...</span>")
			return TRUE		//Wasp End

		if(!organs.len)
			to_chat(user, "<span class='warning'>There are no removable organs in [target]'s [parse_zone(target_zone)]!</span>")
			return -1
		else
			for(var/obj/item/organ/O in organs)
				O.on_find(user)
				organs -= O
				organs[O.name] = O

			I = input("Remove which organ?", "Surgery", null, null) as null|anything in sortList(organs)
			if(I && user && target && user.Adjacent(target) && user.get_active_held_item() == tool)
				I = organs[I]
				if(!I)
					return -1
				display_results(user, target, "<span class='notice'>You begin to extract [I] from [target]'s [parse_zone(target_zone)]...</span>",
					"<span class='notice'>[user] begins to extract [I] from [target]'s [parse_zone(target_zone)].</span>",
					"<span class='notice'>[user] begins to extract something from [target]'s [parse_zone(target_zone)].</span>")
			else
				return -1

/datum/surgery_step/manipulate_organs/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results)
	if(current_type == "posibrain")
		if(istype(tool, /obj/item/organ_storage))
			tool.icon_state = "evidenceobj"
			tool.desc = "A container for holding body parts."
			tool.cut_overlays()
			tool = tool.contents[1]

		user.temporarilyRemoveItemFromInventory(tool)
		spawn(1)
			I = new /obj/item/organ/brain/mmi_holder/posibrain(tool)
			I.Insert(target)
			user.visible_message("<span class='notice'>[user] inserts [tool] into [target]'s [parse_zone(target_zone)]!</span>",
				"<span class='notice'>You insert [tool] into [target]'s [parse_zone(target_zone)].</span>")

	else if(current_type == "insert")
		if(istype(tool, /obj/item/organ_storage))
			I = tool.contents[1]
			tool.icon_state = initial(tool.icon_state)
			tool.desc = initial(tool.desc)
			tool.cut_overlays()
			tool = I
		else
			I = tool
		user.temporarilyRemoveItemFromInventory(I, TRUE)
		I.Insert(target)
		display_results(user, target, "<span class='notice'>You insert [tool] into [target]'s [parse_zone(target_zone)].</span>",
			"<span class='notice'>[user] inserts [tool] into [target]'s [parse_zone(target_zone)]!</span>",
			"<span class='notice'>[user] inserts something into [target]'s [parse_zone(target_zone)]!</span>")

	else if(current_type == "extract")
		//Wasp begin - borers
		var/mob/living/simple_animal/borer/B = target.has_brain_worms()
		if(B && B.victim == target)
			user.visible_message("[user] successfully extracts [B] from [target]'s [parse_zone(target_zone)]!",
				"<span class='notice'>You successfully extract [B] from [target]'s [parse_zone(target_zone)].</span>")
			log_combat(user, target, "surgically removed [B] from", addition="INTENT: [uppertext(user.a_intent)]")
			B.leave_victim()
			return FALSE
		//Wasp end
		if(I && I.owner == target)
			display_results(user, target, "<span class='notice'>You successfully extract [I] from [target]'s [parse_zone(target_zone)].</span>",
				"<span class='notice'>[user] successfully extracts [I] from [target]'s [parse_zone(target_zone)]!</span>",
				"<span class='notice'>[user] successfully extracts something from [target]'s [parse_zone(target_zone)]!</span>")
			log_combat(user, target, "surgically removed [I.name] from", addition="INTENT: [uppertext(user.a_intent)]")
			I.Remove(target)
			I.forceMove(get_turf(target))
		else
			display_results(user, target, "<span class='warning'>You can't extract anything from [target]'s [parse_zone(target_zone)]!</span>",
				"<span class='notice'>[user] can't seem to extract anything from [target]'s [parse_zone(target_zone)]!</span>",
				"<span class='notice'>[user] can't seem to extract anything from [target]'s [parse_zone(target_zone)]!</span>")
	return 0
