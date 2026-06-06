hg.Appearance = hg.Appearance or {}
hg.PointShop = hg.PointShop or {}

hg.Appearance.MenuPerf = hg.Appearance.MenuPerf or {
    showcaseCols = 12,
    allFacemapsCols = 14,
    allFacemapsHeaderGapFactor = 0.43,
    clothesCols = 4,
    facemapCols = 3,
    glovesCols = 3,
    modelCols = 4
}

hg.Appearance.ModelFaceSlots = hg.Appearance.ModelFaceSlots or {}

hg.Appearance.PlayerModels = hg.Appearance.PlayerModels or { [1] = {}, [2] = {} }
hg.Appearance.Clothes = hg.Appearance.Clothes or { [1] = {}, [2] = {} }
hg.Appearance.ClothesDesc = hg.Appearance.ClothesDesc or {}
hg.Appearance.FacemapsSlots = hg.Appearance.FacemapsSlots or {}
hg.Appearance.FacemapsModels = hg.Appearance.FacemapsModels or {}

local function AddCustomModels()
    hg.Appearance.PlayerModels = hg.Appearance.PlayerModels or { [1] = {}, [2] = {} }
    local PlayerModels = hg.Appearance.PlayerModels
    local function AppAddModel(strName, strMdl, bFemale, tSubmaterialSlots)
        PlayerModels[bFemale and 2 or 1][strName] = {
            mdl = strMdl,
            submatSlots = tSubmaterialSlots,
            sex = bFemale
        }
    end
    AppAddModel( "Male 10", "models/slav/m/male_10.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Male Cohrt", "models/slav/m/cohrt.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Male Cheaple", "models/slav/m/cheaple.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Male Eli", "models/slav/m/eli.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Male Barney", "models/slav/m/barney.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Male Bill", "models/slav/m/bill.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Male Travis", "models/slav/m/travis.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Male JohnWick", "models/slav/m/johnwick.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Male Leet", "models/slav/m/leet.mdl", false, {
	    main = "models/humans/male/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })


    AppAddModel( "Female Mossman", "models/slav/f/mossman.mdl", true, {
	    main = "models/humans/female/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Female Zoey", "models/slav/f/zoey.mdl", true, {
	    main = "models/humans/female/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel( "Female BlackMesa", "models/slav/f/scientist_female.mdl", true, {
	    main = "models/humans/female/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    AppAddModel("Female Rochelle", "models/slav/f/rochelle.mdl", true, {
	    main = "models/humans/female/group01/players_sheet",
	    pants = "distac/gloves/pants",
	    boots = "distac/gloves/cross",
	    hands = "distac/gloves/hands"
    })

    hg.Appearance.FuckYouModels = hg.Appearance.FuckYouModels or { {}, {} }
    for name, tbl in pairs(PlayerModels[1]) do
        hg.Appearance.FuckYouModels[1][tbl.mdl] = tbl
    end
    for name, tbl in pairs(PlayerModels[2]) do
        hg.Appearance.FuckYouModels[2][tbl.mdl] = tbl
    end
end

local function AddCustomClothes()
    hg.Appearance.Clothes = hg.Appearance.Clothes or { [1] = {}, [2] = {} }
    hg.Appearance.ClothesDesc = hg.Appearance.ClothesDesc or {}

    local maleClothes = {
        femboy = "models/humans/modern/male/sheet_29",
        yellowjacket = "models/humans/modern/male/sheet_01",
        obh = "models/humans/modern/male/sheet_02",
        plaidblue = "models/humans/modern/male/sheet_03",
        bebra = "models/humans/modern/male/sheet_04",
        bloody = "models/humans/modern/male/sheet_05",
        coolskeleton = "models/humans/modern/male/sheet_08",
        igotwood = "models/humans/modern/male/sheet_09",
        ftptop = "models/humans/modern/male/sheet_10",
        orangetop = "models/humans/modern/male/sheet_11",
        brownjacket = "models/humans/modern/male/sheet_12",
        doralover = "models/humans/modern/male/sheet_13",
        gosling = "models/humans/modern/male/sheet_14",
        dawnofthedead = "models/humans/modern/male/sheet_16",
        corkers = "models/humans/modern/male/sheet_17",
        blackjacket = "models/humans/modern/male/sheet_18",
        adidas = "models/humans/modern/male/sheet_19",
        fur = "models/humans/modern/male/sheet_20",
        leatherjacket = "models/humans/modern/male/sheet_21",
        micah = "models/humans/modern/male/sheet_22",
        whitejacket = "models/humans/modern/male/sheet_23",
        furblack = "models/humans/modern/male/sheet_24",
        greenjacket = "models/humans/modern/male/sheet_25",
        nike = "models/humans/modern/male/sheet_26",
        jeansjacket = "models/humans/modern/male/sheet_27",
        puffer = "models/humans/modern/male/sheet_28",
        stripedjacket = "models/humans/modern/male/sheet_30",
        blackhoodie1 = "models/humans/modern/male/sheet_31",
        adidassheet = "models/humans/slav/adidas_sheet",
	    stoneisland = "models/humans/slav/sheet_si",

	    shirtmale = "models/humans/slav/shirtmale",
		sportsm = "models/humans/slav/sports_sheet",

		autumn_1m = "models/humans/slav/octo/autumn01_sheet",
		autumn_2m = "models/humans/slav/octo/autumn02_sheet",
		autumn_3m = "models/humans/slav/octo/autumn03_sheet",
		autumn_4m = "models/humans/slav/octo/autumn04_sheet",
		autumn_6m = "models/humans/slav/octo/autumn06_sheet",
		autumn_8m = "models/humans/slav/octo/autumn08_sheet",
		autumn_9m = "models/humans/slav/octo/autumn09_sheet",
		autumn_10m = "models/humans/slav/octo/autumn10_sheet",
		autumn_11m = "models/humans/slav/octo/autumn11_sheet",
		autumn_12m = "models/humans/slav/octo/autumn12_sheet",

		halloween_19m = "models/humans/slav/octo/halloween19_sheet",
		halloween_20m = "models/humans/slav/octo/halloween20_sheet",
		halloween_22m = "models/humans/slav/octo/halloween22_sheet",
		halloween_24m = "models/humans/slav/octo/halloween24_sheet",
		halloween_28m = "models/humans/slav/octo/halloween28_sheet",
		halloween_29m = "models/humans/slav/octo/halloween29_sheet",
		halloween_30m = "models/humans/slav/octo/halloween30_sheet",
		halloween_31m = "models/humans/slav/octo/halloween31_sheet",
		halloween_32m = "models/humans/slav/octo/halloween32_sheet",

		hobo_1m = "models/humans/slav/octo/hobo1_sheet",
		hobo_2m = "models/humans/slav/octo/hobo2_sheet",
		hobo_3m = "models/humans/slav/octo/hobo3_sheet",
		hobo_4m = "models/humans/slav/octo/hobo4_sheet",
		hobo_5m = "models/humans/slav/octo/hobo5_sheet",
		hobo_6m = "models/humans/slav/octo/hobo6_sheet",

		sport_1m = "models/humans/slav/octo/sport1_sheet",
		sport_2m = "models/humans/slav/octo/sport2_sheet",
		sport_3m = "models/humans/slav/octo/sport3_sheet",
		sport_4m = "models/humans/slav/octo/sport4_sheet",
		sport_5m = "models/humans/slav/octo/sport5_sheet",
		sport_6m = "models/humans/slav/octo/sport6_sheet",
		sport_7m = "models/humans/slav/octo/sport7_sheet",
		sport_8m = "models/humans/slav/octo/sport8_sheet",
		sport_9m = "models/humans/slav/octo/sport9_sheet",
		sport_10m = "models/humans/slav/octo/sport10_sheet",
		sport_11m = "models/humans/slav/octo/sport11_sheet",
		sport_12m = "models/humans/slav/octo/sport12_sheet",
		sport_13m = "models/humans/slav/octo/sport13_sheet",
		sport_14m = "models/humans/slav/octo/sport14_sheet",
		sport_15m = "models/humans/slav/octo/sport15_sheet",

		standart_1m = "models/humans/slav/octo/standart1_sheet",
		standart_2m = "models/humans/slav/octo/standart2_sheet",
		standart_3m = "models/humans/slav/octo/standart3_sheet",
		standart_4m = "models/humans/slav/octo/standart4_sheet",
		standart_5m = "models/humans/slav/octo/standart5_sheet",
		standart_6m = "models/humans/slav/octo/standart6_sheet",
		standart_7m = "models/humans/slav/octo/standart7_sheet",
		standart_8m = "models/humans/slav/octo/standart8_sheet",
		standart_9m = "models/humans/slav/octo/standart9_sheet",
		standart_10m = "models/humans/slav/octo/standart10_sheet",
		standart_11m = "models/humans/slav/octo/standart11_sheet",
		standart_12m = "models/humans/slav/octo/standart12_sheet",
		standart_13m = "models/humans/slav/octo/standart13_sheet",
		standart_14m = "models/humans/slav/octo/standart14_sheet",
		standart_15m = "models/humans/slav/octo/standart15_sheet",
		standart_16m = "models/humans/slav/octo/standart16_sheet",
		standart_17m = "models/humans/slav/octo/standart17_sheet",
		standart_18m = "models/humans/slav/octo/standart18_sheet",
		standart_19m = "models/humans/slav/octo/standart19_sheet",
		standart_20m = "models/humans/slav/octo/standart20_sheet",
		standart_21m = "models/humans/slav/octo/standart21_sheet",
		standart_22m = "models/humans/slav/octo/standart22_sheet",
		standart_23m = "models/humans/slav/octo/standart23_sheet",

		suit_1m = "models/humans/slav/octo/suit1_sheet",
		suit_2m = "models/humans/slav/octo/suit2_sheet",
		suit_3m = "models/humans/slav/octo/suit3_sheet",
		suit_4m = "models/humans/slav/octo/suit4_sheet",
		suit_5m = "models/humans/slav/octo/suit5_sheet",
		suit_6m = "models/humans/slav/octo/suit6_sheet",
		suit_7m = "models/humans/slav/octo/suit7_sheet",
		suit_8m = "models/humans/slav/octo/suit8_sheet",

		winter_9m = "models/humans/slav/octo/winter9_sheet",
		winter_17m = "models/humans/slav/octo/winter17_sheet",
		winter_19m = "models/humans/slav/octo/winter19_sheet",
		winter_20m = "models/humans/slav/octo/winter20_sheet",
		winter_21m = "models/humans/slav/octo/winter21_sheet",
		winter_22m = "models/humans/slav/octo/winter22_sheet",
		winter_23m = "models/humans/slav/octo/winter23_sheet",
		winter_28m = "models/humans/slav/octo/winter28_sheet",
		winter_29m = "models/humans/slav/octo/winter29_sheet",
		winter_32m = "models/humans/slav/octo/winter32_sheet",
		winter_41m = "models/humans/slav/octo/winter41_sheet",
		winter_44m = "models/humans/slav/octo/winter44_sheet",
		winter_48m = "models/humans/slav/octo/winter48_sheet",

		desertm = "models/humans/slav/desert",
		gunsmith1m = "models/humans/slav/gunsmith1",
		gunsmith2m = "models/humans/slav/gunsmith2",
		multim = "models/humans/slav/multi",
		woodlandm = "models/humans/slav/woodland",

		dbgclothes_1m = "models/humans/slav/dobrogradstuff/clothes/advanced_leon",
		dbgclothes_2m = "models/humans/slav/dobrogradstuff/clothes/afganka",
		dbgclothes_3m = "models/humans/slav/dobrogradstuff/clothes/alfred_clothes_mrthepro",
		dbgclothes_4m = "models/humans/slav/dobrogradstuff/clothes/american_texture_deadkennedy",
		dbgclothes_5m = "models/humans/slav/dobrogradstuff/clothes/american_texture_zeeke",
		dbgclothes_6m = "models/humans/slav/dobrogradstuff/clothes/anotherrad",
		dbgclothes_7m = "models/humans/slav/dobrogradstuff/clothes/baker1",
		dbgclothes_8m = "models/humans/slav/dobrogradstuff/clothes/baker2",
		dbgclothes_9m = "models/humans/slav/dobrogradstuff/clothes/baker3",
		dbgclothes_10m = "models/humans/slav/dobrogradstuff/clothes/blackjacket",
		dbgclothes_11m = "models/humans/slav/dobrogradstuff/clothes/blackjacketwithgoldbuckle",
		dbgclothes_12m = "models/humans/slav/dobrogradstuff/clothes/bobr_2",
		dbgclothes_13m = "models/humans/slav/dobrogradstuff/clothes/carmine_clothes_belch",
		dbgclothes_14m = "models/humans/slav/dobrogradstuff/clothes/casu",
		dbgclothes_15m = "models/humans/slav/dobrogradstuff/clothes/casual",
		dbgclothes_16m = "models/humans/slav/dobrogradstuff/clothes/chillfm",
		dbgclothes_17m = "models/humans/slav/dobrogradstuff/clothes/clotheth_rama",
		dbgclothes_18m = "models/humans/slav/dobrogradstuff/clothes/darkgreenjacket",
		dbgclothes_19m = "models/humans/slav/dobrogradstuff/clothes/dp_sport_jacket",
		dbgclothes_20m = "models/humans/slav/dobrogradstuff/clothes/dpsport_1",
		dbgclothes_21m = "models/humans/slav/dobrogradstuff/clothes/dpsport_b",
		dbgclothes_22m = "models/humans/slav/dobrogradstuff/clothes/evrei",
		dbgclothes_23m = "models/humans/slav/dobrogradstuff/clothes/fedor_clothes",
		dbgclothes_24m = "models/humans/slav/dobrogradstuff/clothes/foo_clothes",
		dbgclothes_25m = "models/humans/slav/dobrogradstuff/clothes/forest",
		dbgclothes_26m = "models/humans/slav/dobrogradstuff/clothes/green_clothes_zeeke",
		dbgclothes_27m = "models/humans/slav/dobrogradstuff/clothes/hoodbiker",
		dbgclothes_28m = "models/humans/slav/dobrogradstuff/clothes/hoodsport",
		dbgclothes_29m = "models/humans/slav/dobrogradstuff/clothes/irish_adidas",
		dbgclothes_30m = "models/humans/slav/dobrogradstuff/clothes/irish_jacket",
		dbgclothes_31m = "models/humans/slav/dobrogradstuff/clothes/irish_mallan",
		dbgclothes_32m = "models/humans/slav/dobrogradstuff/clothes/irish_moran",
		dbgclothes_33m = "models/humans/slav/dobrogradstuff/clothes/irish_oreily1",
		dbgclothes_34m = "models/humans/slav/dobrogradstuff/clothes/irish_oreily2",
		dbgclothes_35m = "models/humans/slav/dobrogradstuff/clothes/jaket_polkovnik",
		dbgclothes_36m = "models/humans/slav/dobrogradstuff/clothes/jaketmaniakdjon",
		dbgclothes_37m = "models/humans/slav/dobrogradstuff/clothes/jenssuitblue",
		dbgclothes_38m = "models/humans/slav/dobrogradstuff/clothes/jenssuitgreen",
		dbgclothes_39m = "models/humans/slav/dobrogradstuff/clothes/jiletbr",
		dbgclothes_40m = "models/humans/slav/dobrogradstuff/clothes/jimmy_clothes_belch",
		dbgclothes_41m = "models/humans/slav/dobrogradstuff/clothes/kennet_sheet",
		dbgclothes_42m = "models/humans/slav/dobrogradstuff/clothes/lqdirector",
		dbgclothes_43m = "models/humans/slav/dobrogradstuff/clothes/memphis_flov_cloth",
		dbgclothes_44m = "models/humans/slav/dobrogradstuff/clothes/mikel_red_odejka",
		dbgclothes_45m = "models/humans/slav/dobrogradstuff/clothes/nikebelch",
		dbgclothes_46m = "models/humans/slav/dobrogradstuff/clothes/nirvanabelch",
		dbgclothes_47m = "models/humans/slav/dobrogradstuff/clothes/nsbomber",
		dbgclothes_48m = "models/humans/slav/dobrogradstuff/clothes/oi",
		dbgclothes_49m = "models/humans/slav/dobrogradstuff/clothes/pidjack1",
		dbgclothes_50m = "models/humans/slav/dobrogradstuff/clothes/pidjackw",
		dbgclothes_51m = "models/humans/slav/dobrogradstuff/clothes/piter_clothes_zeeke",
		dbgclothes_52m = "models/humans/slav/dobrogradstuff/clothes/rigocchisuit",
		dbgclothes_53m = "models/humans/slav/dobrogradstuff/clothes/rosc_bomber",
		dbgclothes_54m = "models/humans/slav/dobrogradstuff/clothes/rosc_redshirt",
		dbgclothes_55m = "models/humans/slav/dobrogradstuff/clothes/ser",
		dbgclothes_56m = "models/humans/slav/dobrogradstuff/clothes/sharp_bomber",
		dbgclothes_57m = "models/humans/slav/dobrogradstuff/clothes/sounds_of_the_ground_no_logo",
		dbgclothes_58m = "models/humans/slav/dobrogradstuff/clothes/stanli_clothes_belch",
		dbgclothes_59m = "models/humans/slav/dobrogradstuff/clothes/sweater151",
		dbgclothes_60m = "models/humans/slav/dobrogradstuff/clothes/vincenzosuit",
		dbgclothes_61m = "models/humans/slav/dobrogradstuff/clothes/whynot",
		dbgclothes_62m = "models/humans/slav/dobrogradstuff/clothes/wolker",
		dbgclothes_63m = "models/humans/slav/dobrogradstuff/clothes/xv_bluesuit_bandizam",
		dbgclothes_64m = "models/humans/slav/dobrogradstuff/clothes/xv_greensuit_bandizam",
		dbgclothes_65m = "models/humans/slav/dobrogradstuff/clothes/xv_puhovik_bandizam",
		dbgclothes_66m = "models/humans/slav/dobrogradstuff/clothes/xv_tacsheet_bandizam",
		dbgclothes_67m = "models/humans/slav/dobrogradstuff/clothes/xv_tacsuitnic_bandizam",
		dbgclothes_68m = "models/humans/slav/dobrogradstuff/clothes/xv_tolstovka_bandizam",
		dbgclothes_69m = "models/humans/slav/dobrogradstuff/clothes/zeeke",
		dbgclothes_70m = "models/humans/slav/dobrogradstuff/clothes/nrider_suit",

		trap_sheet_2m = "models/humans/slav/trap_sheet_2",
		trap_sheet_8m = "models/humans/slav/trap_sheet_8",
		trap_sheet_9m = "models/humans/slav/trap_sheet_9",
		trap_sheet_10m = "models/humans/slav/trap_sheet_10",
		trap_sheet_11m = "models/humans/slav/trap_sheet_11",

		epstein = "models/humans/slav/epstein",
		epstein1 = "models/humans/slav/epstein1",

		camouflage_1 = "models/humans/slav/camo/players_sheet_military_01",
		camouflage_2 = "models/humans/slav/camo/players_sheet_military_02",
		camouflage_3 = "models/humans/slav/camo/players_sheet_military_03",
		camouflage_4 = "models/humans/slav/camo/players_sheet_military_04",
		camouflage_5 = "models/humans/slav/camo/players_sheet_military_05",
		camouflage_6 = "models/humans/slav/camo/players_sheet_military_06",
		camouflage_7 = "models/humans/slav/camo/players_sheet_military_07",
		camouflage_8 = "models/humans/slav/camo/players_sheet_military_08",
		camouflage_9 = "models/humans/slav/camo/players_sheet_military_09",
		camouflage_10 = "models/humans/slav/camo/players_sheet_military_10",
		camouflage_11 = "models/humans/slav/camo/players_sheet_military_11",
		camouflage_12 = "models/humans/slav/camo/players_sheet_military_12",


		spring_1m = "models/humans/slav/octo/spring01_sheet",
		spring_2m = "models/humans/slav/octo/spring02_sheet",
		spring_3m = "models/humans/slav/octo/spring03_sheet",
		spring_4m = "models/humans/slav/octo/spring04_sheet",
		spring_5m = "models/humans/slav/octo/spring05_sheet",
		spring_6m = "models/humans/slav/octo/spring06_sheet",
		spring_7m = "models/humans/slav/octo/spring07_sheet",
		spring_8m = "models/humans/slav/octo/spring08_sheet",
		spring_9m = "models/humans/slav/octo/spring09_sheet",
		spring_10m = "models/humans/slav/octo/spring10_sheet",
		spring_11m = "models/humans/slav/octo/spring11_sheet",
		spring_12m = "models/humans/slav/octo/spring12_sheet",
		spring_13m = "models/humans/slav/octo/spring13_sheet",
		spring_14m = "models/humans/slav/octo/spring14_sheet",
		spring_15m = "models/humans/slav/octo/spring15_sheet",
		spring_16m = "models/humans/slav/octo/spring16_sheet",
		spring_17m = "models/humans/slav/octo/spring17_sheet",
		spring_18m = "models/humans/slav/octo/spring18_sheet",
		spring_19m = "models/humans/slav/octo/spring19_sheet",
		spring_20m = "models/humans/slav/octo/spring20_sheet",
		spring_21m = "models/humans/slav/octo/spring21_sheet",
		spring_22m = "models/humans/slav/octo/spring22_sheet",
		spring_23m = "models/humans/slav/octo/spring23_sheet",

		gentlemen_1m = "models/humans/slav/octo/gentlemen_sheet_1",
		gentlemen_2m = "models/humans/slav/octo/gentlemen_sheet_2",
		gentlemen_3m = "models/humans/slav/octo/gentlemen_sheet_3",
		gentlemen_4m = "models/humans/slav/octo/gentlemen_sheet_4",
		gentlemen_5m = "models/humans/slav/octo/gentlemen_sheet_5",
		gentlemen_6m = "models/humans/slav/octo/gentlemen_sheet_6",

		modern_1m = "models/humans/slav/octo/modern01_sheet",
		modern_2m = "models/humans/slav/octo/modern02_sheet",
		modern_3m = "models/humans/slav/octo/modern03_sheet",
		modern_4m = "models/humans/slav/octo/modern04_sheet",
		modern_5m = "models/humans/slav/octo/modern05_sheet",
		modern_6m = "models/humans/slav/octo/modern06_sheet",
		modern_7m = "models/humans/slav/octo/modern07_sheet",
		modern_8m = "models/humans/slav/octo/modern08_sheet",

		seaman_m = "models/humans/slav/octo/seaman_d",

		wolfslag_m = "models/humans/slav/octo/wolfslag01_sheet",

		halloween_13m = "models/humans/slav/octo/halloween13_sheet",
		halloween_25m = "models/humans/slav/octo/halloween25_sheet",

		winter_45m = "models/humans/slav/octo/winter45_sheet",
		winter_46m = "models/humans/slav/octo/winter46_sheet",
		winter_47m = "models/humans/slav/octo/winter47_sheet",

		nrider_suit_m = "models/humans/slav/nrider_suit",

    }
    for id, path in pairs(maleClothes) do
        hg.Appearance.Clothes[1][id] = path
        hg.Appearance.ClothesDesc[id] = hg.Appearance.ClothesDesc[id] or { desc = "from zcity content." }
    end


    local femaleClothes = {
        shirt1_f = "models/humans/modern/female/sheet_01",
        shirt2_f = "models/humans/modern/female/sheet_02",
        shirt3_f = "models/humans/modern/female/sheet_03",
        pastelcolortop_f = "models/humans/modern/female/sheet_04",
        coloredtop_f = "models/humans/modern/female/sheet_05",
        streetwear_f = "models/humans/modern/female/sheet_06",
        police_f = "models/humans/modern/female/sheet_07",
        bluejacket_f = "models/humans/modern/female/sheet_08",
        greentop_f = "models/humans/modern/female/sheet_09",
        playeboy_f = "models/humans/modern/female/sheet_10",
        kittytop_f = "models/humans/modern/female/sheet_11",
        redtop_f = "models/humans/modern/female/sheet_12",
        purpletop_f = "models/humans/modern/female/sheet_13",
        coat_f = "models/humans/modern/female/sheet_14",
        leatherjacket_f = "models/humans/modern/female/sheet_15",
	    turtleneck_f = "models/roscoe/dogge1",
	    formalshirt_f = "models/roscoe/dogge2",
	    halloween_3f = "models/humans/slav/octo/halloween3_sheet_women",
	    halloween_7f = "models/humans/slav/octo/halloween7_sheet_women",
	    halloween_8f = "models/humans/slav/octo/halloween8_sheet_women",
	    halloween_11f = "models/humans/slav/octo/halloween11_sheet_women",
	    halloween_13f = "models/humans/slav/octo/halloween13_sheet_women",
	    halloween_14f = "models/humans/slav/octo/halloween14_sheet_women",
	    halloween_15f = "models/humans/slav/octo/halloween15_sheet_women",
	    halloween_16f = "models/humans/slav/octo/halloween16_sheet_women",
	    halloween_17f = "models/humans/slav/octo/halloween17_sheet_women",
	    halloween_18f = "models/humans/slav/octo/halloween18_sheet_women",
	    winter_2f = "models/humans/slav/octo/winter2_sheet_woman",
	    winter_4f = "models/humans/slav/octo/winter4_sheet_woman",
	    winter_5f = "models/humans/slav/octo/winter5_sheet_woman",
	    winter_6f = "models/humans/slav/octo/winter6_sheet_woman",
	    winter_7f = "models/humans/slav/octo/winter7_sheet_woman",
	    winter_8f = "models/humans/slav/octo/winter8_sheet_woman",
	    winter_9f = "models/humans/slav/octo/winter9_sheet_woman",
	    winter_10f = "models/humans/slav/octo/winter10_sheet_woman",
	    winter_12f = "models/humans/slav/octo/winter12_sheet_woman",
	    winter_13f = "models/humans/slav/octo/winter13_sheet_woman",
	    winter_15f = "models/humans/slav/octo/winter15_sheet_woman",
	    winter_16f = "models/humans/slav/octo/winter16_sheet_woman",
	    winter_17f = "models/humans/slav/octo/winter17_sheet_woman",

		dksclothes6f = "models/humans/slav/dksclothes6",
		bluecheckshirtf = "models/humans/slav/dobrogradstuff/clothes/bluecheckshirt",

		tanktopf = "models/humans/slav/tanktop_f",

		winter_18f = "models/humans/slav/octo/winter18_sheet_woman",
    	winter_19f = "models/humans/slav/octo/winter19_sheet_woman",

    }
    for id, path in pairs(femaleClothes) do
        hg.Appearance.Clothes[2][id] = path
        hg.Appearance.ClothesDesc[id] = hg.Appearance.ClothesDesc[id] or { desc = "from zcity content." }
    end




    hg.Appearance.ClothesDesc.femboy = { desc = "from zcity content." }
    hg.Appearance.ClothesDesc.yellowjacket = { desc = "from zcity content." }
    hg.Appearance.ClothesDesc.obh = { desc = "from zcity content." }

    hg.Appearance.ClothesDesc.bebra = { desc = "from zcity content." }
    hg.Appearance.ClothesDesc.bloody = { desc = "from zcity content." }
    hg.Appearance.ClothesDesc.coolskeleton = { desc = "from zcity content." }

    hg.Appearance.ClothesDesc.ftptop = {
		desc = "from zcity content."
	}

    hg.Appearance.ClothesDesc.brownjacket = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.doralover = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.gosling = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.dawnofthedead = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.corkers = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.blackjacket = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.adidas = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.fur = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.leatherjacket = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.micah = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.whitejacket = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.furblack = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.greenjacket = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.nike = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.jeansjacket = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.puffer = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.stripedjacket = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.blackhoodie1 = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.shirt1_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.shirt2_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.shirt3_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.pastelcolortop_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.coloredtop_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.streetwear_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.police_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.bluejacket_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.greentop_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.playeboy_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.kittytop_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.redtop_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.purpletop_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.coat_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.leatherjacket_f = {
		desc = "from zcity content."
	}
    hg.Appearance.ClothesDesc.adidassheet = {
		desc = "adidas clothes from workshop"
	}
	hg.Appearance.ClothesDesc.stoneisland = {
		desc = "stone island clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.turtleneck_f = {
		desc = "turtleneck clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.formalshirt_f = {
		desc = "formal shirt clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_3f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_7f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_8f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_11f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_13f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_14f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_15f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_16f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_17f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_18f = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_2f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_4f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_5f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_6f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_7f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_8f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_9f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_10f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_12f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_13f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_15f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_16f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.winter_17f = {
		desc = "winter clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.shirtmale = {
		desc = "by flada"
	}

	hg.Appearance.ClothesDesc.autumn_1m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_2m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_3m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_4m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_6m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_8m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_9m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_10m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_11m = {
		desc = "autumn clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.autumn_12m = {
		desc = "autumn clothes from dobrograd content"
	}

	hg.Appearance.ClothesDesc.halloween_19m = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_20m = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_22m = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_24m = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_28m = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_29m = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_30m = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_31m = {
		desc = "halloween clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.halloween_32m = {
		desc = "halloween clothes from dobrograd content"
	}

	hg.Appearance.ClothesDesc.hobo_1m = {
		desc = "hobo clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.hobo_2m = {
		desc = "hobo clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.hobo_3m = {
		desc = "hobo clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.hobo_4m = {
		desc = "hobo clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.hobo_5m = {
		desc = "hobo clothes from dobrograd content"
	}
	hg.Appearance.ClothesDesc.hobo_6m = {
		desc = "hobo clothes from dobrograd content"
	}




end

local function AddCustomFacemaps()
    hg.Appearance.FacemapsSlots = hg.Appearance.FacemapsSlots or {}
    hg.Appearance.FacemapsModels = hg.Appearance.FacemapsModels or {}

	hg.Appearance.MultiFacemaps = hg.Appearance.MultiFacemaps or {}



	local FacemapSlotModels = {}

	    local function AddFacemap(matOverride, strName, matMaterial, model)
        hg.Appearance.FacemapsSlots[matOverride] = hg.Appearance.FacemapsSlots[matOverride] or {}
        hg.Appearance.FacemapsSlots[matOverride][strName] = matMaterial

		local targetModels = {}
        if model then
            model = string.lower(model)
			hg.Appearance.FacemapsModels[model] = matOverride

			hg.Appearance.ModelFaceSlots[model] = hg.Appearance.ModelFaceSlots[model] or {}
			hg.Appearance.ModelFaceSlots[model][matOverride] = true

			FacemapSlotModels[matOverride] = FacemapSlotModels[matOverride] or {}
			FacemapSlotModels[matOverride][model] = true
			targetModels = FacemapSlotModels[matOverride]
		elseif FacemapSlotModels[matOverride] then
				targetModels = FacemapSlotModels[matOverride]
		end

		for modelPath, _ in pairs(targetModels) do
			hg.Appearance.MultiFacemaps[modelPath] = hg.Appearance.MultiFacemaps[modelPath] or {}
			hg.Appearance.MultiFacemaps[modelPath][strName] = hg.Appearance.MultiFacemaps[modelPath][strName] or {}
			hg.Appearance.MultiFacemaps[modelPath][strName][matOverride] = matMaterial
		end

    end



	AddFacemap("models/humans/male/group01/ted_facemap","Face 11 (New)","models/humans/modern/male/male_02/facemap_01", "models/zcity/m/male_02.mdl")

	AddFacemap("models/humans/male/group01/joe_facemap","Face 10 (New)","models/humans/modern/male/male_03/facemap_03", "models/zcity/m/male_03.mdl")
	AddFacemap("models/humans/male/group01/joe_facemap","Face 11 (New)","models/humans/modern/male/male_03/facemap_04", "models/zcity/m/male_03.mdl")
	AddFacemap("models/humans/male/group01/joe_facemap","Face 12 (New)","models/humans/modern/male/male_03/facemap_06", "models/zcity/m/male_03.mdl")

	AddFacemap("models/humans/male/group01/eric_facemap","Face 10 (New)","models/humans/modern/male/male_04/facemap_01", "models/zcity/m/male_04.mdl")
	AddFacemap("models/humans/male/group01/eric_facemap","Face 11 (New)","models/humans/modern/male/male_04/facemap_02", "models/zcity/m/male_04.mdl")
	AddFacemap("models/humans/male/group01/eric_facemap","Face 12 (New)","models/humans/modern/male/male_04/facemap_03", "models/zcity/m/male_04.mdl")
	AddFacemap("models/humans/male/group01/eric_facemap","Face 13 (New)","models/humans/modern/male/male_04/facemap_04", "models/zcity/m/male_04.mdl")
	AddFacemap("models/humans/male/group01/eric_facemap","Face 14 (New)","models/characters/citizen/male/facemaps/eric_facemap", "models/zcity/m/male_04.mdl")
	AddFacemap("models/humans/male/group01/eric_facemap","Face 15 (New)","models/humans/slav/dobrogradstuff/lacharro_face", "models/zcity/m/male_04.mdl")
	AddFacemap("models/humans/male/group01/eric_facemap","Face 16 (New)","models/humans/slav/dobrogradstuff/mikel_red", "models/zcity/m/male_04.mdl")
	AddFacemap("models/humans/male/group01/eric_facemap","Face 17 (New)","models/humans/slav/dobrogradstuff/serface", "models/zcity/m/male_04.mdl")
	AddFacemap("models/humans/male/group01/eric_facemap","Face 18 (New)","models/humans/slav/dobrogradstuff/xv_simonrus_bandizam", "models/zcity/m/male_04.mdl")

	AddFacemap("models/humans/male/group01/art_facemap","Face 10 (New)","models/humans/modern/male/male_05/facemap_05", "models/zcity/m/male_05.mdl")
	AddFacemap("models/humans/male/group01/art_facemap","Face 11 (New)","models/humans/slav/art/art_facemap1", "models/zcity/m/male_05.mdl")
	AddFacemap("models/humans/male/group01/art_facemap","Face 12 (New)","models/humans/slav/art/art_facemap2", "models/zcity/m/male_05.mdl")
	AddFacemap("models/humans/male/group01/art_facemap","Face 13 (New)","models/humans/slav/art/art_facemap3", "models/zcity/m/male_05.mdl")
	AddFacemap("models/humans/male/group01/art_facemap","Face 14 (New)","models/humans/slav/art/art_facemap4", "models/zcity/m/male_05.mdl")

	AddFacemap("models/humans/male/group01/sandro_facemap","Face 11 (New)","models/humans/modern/male/male_06/facemap_02", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 12 (New)","models/humans/modern/male/male_06/facemap_03", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 13 (New)","models/humans/modern/male/male_06/facemap_04", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 14 (New)","models/humans/modern/male/male_06/facemap_05", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 15 (New)","models/characters/citizen/male/facemaps/sandro_facemap6", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 16 (New)","models/humans/slav/tanned_facemap", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 17 (New)","models/humans/slav/dobrogradstuff/american_face_zeeke", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 18 (New)","models/humans/slav/dobrogradstuff/golovastik", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 19 (New)","models/humans/slav/dobrogradstuff/golovastik_nordd1", "models/zcity/m/male_06.mdl")
	AddFacemap("models/humans/male/group01/sandro_facemap","Face 20 (New)","models/humans/slav/dobrogradstuff/xv_shirnymark_father", "models/zcity/m/male_06.mdl")

	AddFacemap("models/humans/male/group01/mike_facemap","Face 9 (New)","models/humans/modern/male/male_07/facemap_01", "models/zcity/m/male_07.mdl")
	AddFacemap("models/humans/male/group01/mike_facemap","Face 10 (New)","models/humans/slav/dobrogradstuff/american_face_old_male07", "models/zcity/m/male_07.mdl")
	AddFacemap("models/humans/male/group01/mike_facemap","Face 11 (New)","models/humans/slav/dobrogradstuff/harley_face_belch", "models/zcity/m/male_07.mdl")
	AddFacemap("models/humans/male/group01/mike_facemap","Face 12 (New)","models/humans/slav/dobrogradstuff/lybitelpivasa", "models/zcity/m/male_07.mdl")
	AddFacemap("models/humans/male/group01/mike_facemap","Face 13 (New)","models/humans/slav/dobrogradstuff/xv_erik_susig", "models/zcity/m/male_07.mdl")
	AddFacemap("models/humans/male/group01/mike_facemap","Face 14 (New)","models/humans/slav/dobrogradstuff/xv_greg_bandizam", "models/zcity/m/male_07.mdl")
	AddFacemap("models/humans/male/group01/mike_facemap","Face 15 (New)","models/humans/slav/dobrogradstuff/xv_nikitashevchuk_bandizam", "models/zcity/m/male_07.mdl")
	AddFacemap("models/humans/male/group01/mike_facemap","Face 16 (New)","models/humans/slav/dobrogradstuff/facenr07", "models/zcity/m/male_07.mdl")

	AddFacemap("models/humans/male/group01/vance_facemap","Face 10 (New)","models/humans/modern/male/male_08/facemap_02", "models/zcity/m/male_08.mdl")
	AddFacemap("models/humans/male/group01/vance_facemap","Face 11 (New)","models/characters/citizen/male/facemaps/vance_facemap", "models/zcity/m/male_08.mdl")
	AddFacemap("models/humans/male/group01/vance_facemap","Face 12 (New)","models/humans/slav/dobrogradstuff/american_face_deadkennedy", "models/zcity/m/male_08.mdl")
	AddFacemap("models/humans/male/group01/vance_facemap","Face 13 (New)","models/humans/slav/dobrogradstuff/bobr_1", "models/zcity/m/male_08.mdl")
	AddFacemap("models/humans/male/group01/vance_facemap","Face 14 (New)","models/humans/slav/dobrogradstuff/xv_nicholas_bandizam", "models/zcity/m/male_08.mdl")

	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 12 (New)","models/humans/modern/male/male_09/facemap_01", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 13 (New)","models/humans/modern/male/male_09/facemap_02", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 14 (New)","models/humans/modern/male/male_09/facemap_04", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 15 (New)","models/characters/citizen/male/facemaps/erdim_facemap", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 16 (New)","models/humans/slav/dobrogradstuff/advanced_aller", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 17 (New)","models/humans/slav/dobrogradstuff/ash", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 18 (New)","models/humans/slav/dobrogradstuff/carmine_face_belch", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 19 (New)","models/humans/slav/dobrogradstuff/face_rama", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 20 (New)","models/humans/slav/dobrogradstuff/facemap_kolchak", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 21 (New)","models/humans/slav/dobrogradstuff/golova_stick", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 22 (New)","models/humans/slav/dobrogradstuff/sergey", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 23 (New)","models/humans/slav/dobrogradstuff/vepran", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 24 (New)","models/humans/slav/dobrogradstuff/nrider_face", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 25 (New)","models/humans/slav/dobrogradstuff/facenr0901", "models/zcity/m/male_09.mdl")
	AddFacemap("models/humans/male/group01/erdim_cylmap","Face 26 (New)","models/humans/slav/dobrogradstuff/facenr0902", "models/zcity/m/male_09.mdl")















    AddFacemap("models/humans/female/group01/naomi_facemap", "Face 7", "models/bloo_ltcom_zel/citizens/facemaps/naomi_facemap_new", "models/zcity/f/female_06.mdl")



    local mossmanfacemap = "models/mossman/mossman_face"
	local mossmanhair = "models/mossman/mossman_hair"
	AddFacemap(mossmanfacemap,"Default","","models/slav/f/mossman.mdl")
	AddFacemap(mossmanhair,"Default","","models/slav/f/mossman.mdl")
	AddFacemap(mossmanfacemap,"Face 1","models/humans/slav/mossman/mossman_face1")
	AddFacemap(mossmanhair,"Face 1","models/humans/slav/mossman/mossman_hair1")
	AddFacemap(mossmanfacemap,"Face 2","models/humans/slav/mossman/mossman_goth_face")
	AddFacemap(mossmanhair,"Face 2","models/humans/slav/mossman/mossman_goth_hair")

	local zoeyfacemap = "models/humans/slav/zoey/zoey_head"
	local zoeyhair = "models/humans/slav/zoey/zoey_hair"
	AddFacemap(zoeyfacemap,"Default","","models/slav/f/zoey.mdl")
	AddFacemap(zoeyhair,"Default","","models/slav/f/zoey.mdl")
	AddFacemap(zoeyfacemap,"Face 1","models/humans/slav/zoey/zoey_head_freckles")
	AddFacemap(zoeyhair,"Face 1","models/humans/slav/zoey/zoey_hair")
	AddFacemap(zoeyfacemap,"Face 2","models/humans/slav/zoey/zoey_head_goth")
	AddFacemap(zoeyhair,"Face 2","models/humans/slav/zoey/zoey_hair_dark")
	AddFacemap(zoeyfacemap,"Face 3","models/humans/slav/zoey/zoey_head_light")
	AddFacemap(zoeyhair,"Face 3","models/humans/slav/zoey/zoey_hair_dark")
	AddFacemap(zoeyfacemap,"Face 4","models/humans/slav/zoey/zoey_head_makeup")
	AddFacemap(zoeyhair,"Face 4","models/humans/slav/zoey/zoey_hair")
	AddFacemap(zoeyfacemap,"Face 4","models/humans/slav/zoey/zoey_head_eyes")
	AddFacemap(zoeyhair,"Face 4","models/humans/slav/zoey/zoey_hair")

	local femalebmsfacemap = "models/humans/slav/blackmesa/base_female/base_f_d"
	local femalebmshair = "models/humans/slav/blackmesa/hair_trans_blonde"
	local femalebmsbody = "models/humans/slav/bodygroups/female_body_new"

	AddFacemap(femalebmsfacemap, "Default", "", "models/slav/f/scientist_female.mdl")
	AddFacemap(femalebmshair, "Default", "", "models/slav/f/scientist_female.mdl")
	AddFacemap(femalebmsbody, "Default", "", "models/slav/f/scientist_female.mdl")

	AddFacemap(femalebmsfacemap, "Face 1", "models/humans/slav/blackmesa/base_female/base_f_02_d")
	AddFacemap(femalebmshair, "Face 1", "models/humans/slav/blackmesa/hair_trans_grey")
	AddFacemap(femalebmsbody, "Face 1", "models/humans/slav/bodygroups/female_body_new")

	AddFacemap(femalebmsfacemap, "Face 2", "models/humans/slav/blackmesa/base_female/base_f_03_d")
	AddFacemap(femalebmshair, "Face 2", "models/humans/slav/blackmesa/hair_trans_brown")
	AddFacemap(femalebmsbody, "Face 2", "models/humans/slav/bodygroups/female_body_new")

	AddFacemap(femalebmsfacemap, "Face 3", "models/humans/slav/blackmesa/base_female/base_f_04_d")
	AddFacemap(femalebmshair, "Face 3", "models/humans/slav/blackmesa/hair_trans_blonde2")
	AddFacemap(femalebmsbody, "Face 3", "models/humans/slav/bodygroups/female_body_new")

	AddFacemap(femalebmsfacemap, "Face 4", "models/humans/slav/blackmesa/base_female/base_f_05_d")
	AddFacemap(femalebmshair, "Face 4", "models/humans/slav/blackmesa/hair_trans_black")
	AddFacemap(femalebmsbody, "Face 4", "models/humans/slav/bodygroups/female_body_new_b")

	AddFacemap(femalebmsfacemap, "Face 5", "models/humans/slav/blackmesa/base_female/base_f_06_d")
	AddFacemap(femalebmshair, "Face 5", "models/humans/slav/blackmesa/hair_trans")
	AddFacemap(femalebmsbody, "Face 5", "models/humans/slav/bodygroups/female_body_new_z")

	AddFacemap(femalebmsfacemap, "Face 6", "models/humans/slav/blackmesa/base_female/base_f_07_d")
	AddFacemap(femalebmshair, "Face 6", "models/humans/slav/blackmesa/hair_trans_black")
	AddFacemap(femalebmsbody, "Face 6", "models/humans/slav/bodygroups/female_body_new_b")

	AddFacemap(femalebmsfacemap, "Face Mia", "models/humans/slav/blackmesa/base_female/base_f_mia_d")
	AddFacemap(femalebmshair, "Face Mia", "models/humans/slav/blackmesa/hair_trans_black")
	AddFacemap(femalebmsbody, "Face Mia", "models/humans/slav/bodygroups/female_body_new")

	AddFacemap(femalebmsfacemap, "Face Wendy", "models/humans/slav/blackmesa/base_female/base_f_wendy_d")
	AddFacemap(femalebmshair, "Face Wendy", "models/humans/slav/blackmesa/hair_trans_grey2")
	AddFacemap(femalebmsbody, "Face Wendy", "models/humans/slav/bodygroups/female_body_new")

	AddFacemap(femalebmsfacemap, "Face Edith", "models/humans/slav/blackmesa/base_female/base_f_edith_d")
	AddFacemap(femalebmshair, "Face Edith", "models/humans/slav/blackmesa/hair_trans_red")
	AddFacemap(femalebmsbody, "Face Edith", "models/humans/slav/bodygroups/female_body_new")

	local rochellefacemap = "models/humans/slav/rochelletrs/trs_rochelle_head"
	AddFacemap(rochellefacemap, "Default", "", "models/slav/f/rochelle.mdl")
	AddFacemap(rochellefacemap, "Face 1", "models/humans/slav/rochelletrs/trs_rochelle_head_1")
	AddFacemap(rochellefacemap, "Face 2", "models/humans/slav/rochelletrs/trs_rochelle_head_2")
	AddFacemap(rochellefacemap, "Face 3", "models/humans/slav/rochelletrs/trs_rochelle_head_3")
	AddFacemap(rochellefacemap, "Face 4", "models/humans/slav/rochelletrs/trs_rochelle_head_4")
	AddFacemap(rochellefacemap, "Face 5", "models/humans/slav/rochelletrs/trs_rochelle_head_5")




	local male10facemap = "models/humans/male/group01/cub_facemap"
	AddFacemap(male10facemap,"Default","","models/slav/m/male_10.mdl")
	AddFacemap(male10facemap,"Face 1","models/humans/male/group02/cub_facemap")
	AddFacemap(male10facemap,"Face 2","models/humans/male/group03/cub_facemap")
	AddFacemap(male10facemap,"Face 3","models/humans/male/group03m/cub_facemap")

	local cohrtfacemap = "models/humans/slav/cohrt/cohrt"
	AddFacemap(cohrtfacemap, "Default", "","models/slav/m/cohrt.mdl")

	local cheaplefacemap = "models/gregrogers/warren/gregrogers_warren_facemap"
	AddFacemap(cheaplefacemap, "Default", "","models/slav/m/cheaple.mdl")
	AddFacemap(cheaplefacemap, "Face 1", "models/gregrogers/warren/gregrogers_warren_facemap_g02")
	AddFacemap(cheaplefacemap, "Face 2", "models/gregrogers/warren/gregrogers_warren_facemap_g03")
	AddFacemap(cheaplefacemap, "Face 3", "models/gregrogers/warren/gregrogers_warren_facemap_g03m")

	local elifacemap = "models/eli/eli_tex4z"
	AddFacemap(elifacemap, "Default", "","models/slav/m/eli.mdl")
	AddFacemap(elifacemap, "Face 1", "models/gang_ballas_boss/gang_ballas_boss_face")
	AddFacemap(elifacemap, "Face 2", "models/humans/slav/eli/eli_headz")

	local barneyfacemap = "models/humans/slav/barney/barneyface"
	AddFacemap(barneyfacemap, "Default", "","models/slav/m/barney.mdl")
	AddFacemap(barneyfacemap, "Face 1", "models/humans/slav/barney/donaldface")

	local billcig = "models/humans/slav/bill/bill_head"
	local billhairs = "models/humans/slav/bill/bill_hairs"
	local billhairs2 = "models/humans/slav/bill/bill_hairs2"
	local billbeard = "models/humans/slav/bill/bill_hair"
	local billface = "models/humans/slav/bill/bill_head_nohat"
	AddFacemap(billcig, "Default", "","models/slav/m/bill.mdl")
	AddFacemap(billhairs, "Default", "","models/slav/m/bill.mdl")
	AddFacemap(billhairs2, "Default", "","models/slav/m/bill.mdl")
	AddFacemap(billbeard, "Default", "","models/slav/m/bill.mdl")
	AddFacemap(billface, "Default", "","models/slav/m/bill.mdl")

	AddFacemap(billcig, "No Cig", "null")
	AddFacemap(billhairs, "No Cig", "models/humans/slav/bill/bill_hairs")
	AddFacemap(billhairs2, "No Cig", "models/humans/slav/bill/bill_hairs2")
	AddFacemap(billbeard, "No Cig", "models/humans/slav/bill/bill_hair")
	AddFacemap(billface, "No Cig", "models/humans/slav/bill/bill_head_nohat")

	AddFacemap(billcig, "Young", "models/humans/slav/bill/bill_head")
	AddFacemap(billhairs, "Young", "models/humans/slav/bill/bill_hairs_young")
	AddFacemap(billhairs2, "Young", "models/humans/slav/bill/bill_hairs_young2")
	AddFacemap(billbeard, "Young", "models/humans/slav/bill/bill_hair_young")
	AddFacemap(billface, "Young", "models/humans/slav/bill/bill_head_young_nohat")

	AddFacemap(billcig, "Young No Beard", "models/humans/slav/bill/bill_head")
	AddFacemap(billhairs, "Young No Beard", "models/humans/slav/bill/bill_hairs_young")
	AddFacemap(billhairs2, "Young No Beard", "models/humans/slav/bill/bill_hairs_young2")
	AddFacemap(billbeard, "Young No Beard", "null")
	AddFacemap(billface, "Young No Beard", "models/humans/slav/bill/bill_head_young_nohat")

	AddFacemap(billcig, "Young No Cig", "null")
	AddFacemap(billhairs, "Young No Cig", "models/humans/slav/bill/bill_hairs_young")
	AddFacemap(billhairs2, "Young No Cig", "models/humans/slav/bill/bill_hairs_young2")
	AddFacemap(billbeard, "Young No Cig", "models/humans/slav/bill/bill_hair_young")
	AddFacemap(billface, "Young No Cig", "models/humans/slav/bill/bill_head_young_nohat")

	AddFacemap(billcig, "Young No Beard No Cig", "null")
	AddFacemap(billhairs, "Young No Beard No Cig", "models/humans/slav/bill/bill_hairs_young")
	AddFacemap(billhairs2, "Young No Beard No Cig", "models/humans/slav/bill/bill_hairs_young2")
	AddFacemap(billbeard, "Young No Beard No Cig", "null")
	AddFacemap(billface, "Young No Beard No Cig", "models/humans/slav/bill/bill_head_young_nohat")

	local travisfacemap = "models/humans/slav/travis/trav_facemap"
	AddFacemap(travisfacemap, "Default", "","models/slav/m/travis.mdl")
	AddFacemap(travisfacemap, "Face 1", "models/humans/slav/travis/trav_facemap1")
	AddFacemap(travisfacemap, "Face 2", "models/humans/slav/travis/trav_facemap2")

	local johnwickfacemap = "models/humans/slav/johnwick/wick_head"
	AddFacemap(johnwickfacemap, "Default", "","models/slav/m/johnwick.mdl")

	local leetfacemap = "models/cstrike/t_leet"
	AddFacemap(leetfacemap, "Default", "","models/slav/m/leet.mdl")

end

local function AddCustomBodygroups()







    hg.Appearance.Bodygroups = hg.Appearance.Bodygroups or { HANDS = { [1] = { ["None"] = {"hands", false} }, [2] = { ["None"] = {"hand_f", false} } } }


    local function AppAddBodygroup(strBodyGroup, strName, strStringID, bFemale, bPointShop, bDonateOnly, fCost, psModel, psBodygroups, psSubmats, psStrNameOveride)
        local pointShopID = "Standard_BodyGroups_" .. (psStrNameOveride or strName)

        hg.Appearance.Bodygroups[strBodyGroup] = hg.Appearance.Bodygroups[strBodyGroup] or {}
        hg.Appearance.Bodygroups[strBodyGroup][bFemale and 2 or 1] = hg.Appearance.Bodygroups[strBodyGroup][bFemale and 2 or 1] or {}
        hg.Appearance.Bodygroups[strBodyGroup][bFemale and 2 or 1][strName] = {
            strStringID,
            bPointShop,
            ID = pointShopID
        }

        if hg.PointShop and hg.PointShop.CreateItem then
            hg.PointShop:CreateItem(pointShopID, string.NiceName(strName), psModel or "models/zcity/gloves/degloves.mdl", psBodygroups, 0, Vector(0, 0, 0), fCost, bDonateOnly, psSubmats or {})
        else
            print("[CustomAppearance] Ошибка: hg.PointShop:CreateItem не найден!")
        end
    end


    AppAddBodygroup("HANDS", "Gloves", "reggloves_FIN_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 0)
	AppAddBodygroup("HANDS", "Gloves", "reggloves_FIN_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 0)
	AppAddBodygroup("HANDS", "Gloves fingerless", "reggloves_outFIN_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 1)
	AppAddBodygroup("HANDS", "Gloves fingerless", "reggloves_outFIN_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 1)
	AppAddBodygroup("HANDS", "Skilet", "sceletgloves_FIN_M", false, true, true, 399, "models/zcity/gloves/degloves.mdl", 0, {
		[0] = "distac/gloves/sceletgloves"
	})

	AppAddBodygroup("HANDS", "Skilet", "sceletgloves_FIN_F", true, true, true, 399, "models/zcity/gloves/degloves.mdl", 0, {
		[0] = "distac/gloves/sceletgloves"
	})

	AppAddBodygroup("HANDS", "Skilet fingerless", "sceletgloves_outFIN_M", false, true, true, 399, "models/zcity/gloves/degloves.mdl", 1, {
		[0] = "distac/gloves/sceletgloves"
	})

	AppAddBodygroup("HANDS", "Skilet fingerless", "sceletgloves_outFIN_F", true, true, true, 399, "models/zcity/gloves/degloves.mdl", 1, {
		[0] = "distac/gloves/sceletgloves"
	})

	AppAddBodygroup("HANDS", "Winter", "wingloves_FIN_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 2, nil, "Bikers")
	AppAddBodygroup("HANDS", "Winter", "wingloves_FIN_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 2, nil, "Bikers")
	AppAddBodygroup("HANDS", "Winter fingerless", "wingloves_outFIN_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 3, nil, "Bikers fingerless")
	AppAddBodygroup("HANDS", "Winter fingerless", "wingloves_outFIN_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 3, nil, "Bikers fingerless")
	AppAddBodygroup("HANDS", "Bikers gloves", "biker_gloves_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 5)
	AppAddBodygroup("HANDS", "Bikers gloves", "biker_gloves_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 5)
	AppAddBodygroup("HANDS", "Bikers wool", "bikerwool_gloves_M", false, true, true, 399, "models/zcity/gloves/degloves.mdl", 6, nil)
	AppAddBodygroup("HANDS", "Bikers wool", "bikerwool_gloves_F", true, true, true, 399, "models/zcity/gloves/degloves.mdl", 6, nil)
	AppAddBodygroup("HANDS", "Wool fingerless", "wool_glove_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 7, nil)
	AppAddBodygroup("HANDS", "Wool fingerless", "wool_gloves_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 7, nil)
	AppAddBodygroup("HANDS", "Mitten wool", "mittenwool_M", false, true, true, 300, "models/zcity/gloves/degloves.mdl", 8, nil)
	AppAddBodygroup("HANDS", "Mitten wool", "mittenwool_F", true, true, true, 300, "models/zcity/gloves/degloves.mdl", 8, nil)







	AppAddBodygroup("sheet", "Standard", "sheet_m", false, false, false, 0, nil, 0)
	AppAddBodygroup("sheet", "T-Shirt", "sheet_tshirt_m", false, false, false, 0, nil, 1)
	AppAddBodygroup("sheet", "Hoodie", "sheet_hood_m", false, false, false, 0, nil, 2)
	AppAddBodygroup("sheet", "Closed", "sheet_closed_m", false, false, false, 0, nil, 3)
	AppAddBodygroup("sheet", "Odessa", "sheet_odessa_m", false, false, false, 0, nil, 4)
	AppAddBodygroup("sheet", "Wide", "sheet_wide_m", false, false, false, 0, nil, 5)
	AppAddBodygroup("sheet", "Wide Jacket", "sheet_wide_jacket_m", false, false, false, 0, nil, 6)


	AppAddBodygroup("pants", "Standard", "pants_m", false, false, false, 0, nil, 0)
	AppAddBodygroup("pants", "Wide", "pants_wide_m", false, false, false, 0, nil, 1)
	AppAddBodygroup("pants", "Shorts", "shorts_m", false, false, false, 0, nil, 2)
	AppAddBodygroup("pants", "Army", "army_pants_m", false, false, false, 0, nil, 3)


	AppAddBodygroup("shoes", "Standard", "shoes_m", false, false, false, 0, nil, 0)
	AppAddBodygroup("shoes", "Sneakers", "shoes_02_m", false, false, false, 0, nil, 1)
	AppAddBodygroup("shoes", "High Top", "shoes_03_m", false, false, false, 0, nil, 2)
	AppAddBodygroup("shoes", "Army", "army_boots_m", false, false, false, 0, nil, 3)




	AppAddBodygroup("sheet", "Standard", "sheet_f", true, false, false, 0, nil, 0)
	AppAddBodygroup("sheet", "T-Shirt", "sheet_tshirt_f", true, false, false, 0, nil, 1)
	AppAddBodygroup("sheet", "Wide", "sheet_wide_f", true, false, false, 0, nil, 2)
	AppAddBodygroup("sheet", "Mossman", "sheet_mossman_f", true, false, false, 0, nil, 3)
	AppAddBodygroup("sheet", "Tank Top", "tanktop_f", true, false, false, 0, nil, 3)


	AppAddBodygroup("pants", "Standard", "pants_f", true, false, false, 0, nil, 0)
	AppAddBodygroup("pants", "Skinny", "pants_02_f", true, false, false, 0, nil, 1)
	AppAddBodygroup("pants", "Shorts", "shorts_f", true, false, false, 0, nil, 1)


	AppAddBodygroup("shoes", "Standard Shoes", "shoes_f", true, false, false, 0, nil, 0)
	AppAddBodygroup("shoes", "Ballet Flats", "shoes_02_f", true, false, false, 0, nil, 1)

end

hook.Add("Initialize", "CustomAppearance_Init", function()
    AddCustomModels()
    AddCustomClothes()
    AddCustomFacemaps()

end)

hook.Add("ZPointshopLoaded", "CustomAppearance_AddBodygroups", function()
    AddCustomBodygroups()
end)

local function ZCity_AddAllCustomContent()
    AddCustomModels()
    AddCustomClothes()
    AddCustomFacemaps()
	AddCustomBodygroups()
end

hook.Add("InitPostEntity", "ZCity_LoadCustomAppearance", function()
    ZCity_AddAllCustomContent()
end)

hook.Add("OnGamemodeLoaded", "ZCity_LoadCustomAppearance", function()
    ZCity_AddAllCustomContent()
end)

hook.Add("PostGamemodeLoaded", "ZCity_LoadCustomAppearance_PostGM", function()
    ZCity_AddAllCustomContent()
end)

if SERVER then
    local function PatchAppearanceReset()
        local appearanceTable = hg.Appearance
        if not appearanceTable or appearanceTable.__ZCitySubmaterialResetPatched then return end
        local originalForceApply = appearanceTable.ForceApplyAppearance
        if not isfunction(originalForceApply) then return end

        appearanceTable.__ZCitySubmaterialResetPatched = true
        appearanceTable.ForceApplyAppearance = function(ply, tbl, noModelChange)
            if IsValid(ply) and ply.GetMaterials and ply.SetSubMaterial then
                local mats = ply:GetMaterials() or {}
                for i = 1, #mats do
                    ply:SetSubMaterial(i - 1, nil)
                end
            end

            return originalForceApply(ply, tbl, noModelChange)
        end
    end

    hook.Add("InitPostEntity", "ZCity_PatchForceApplyAppearanceReset", function()
        PatchAppearanceReset()
        timer.Create("ZCity_PatchForceApplyAppearanceResetRetry", 0.5, 20, function()
            if hg.Appearance and hg.Appearance.__ZCitySubmaterialResetPatched then
                timer.Remove("ZCity_PatchForceApplyAppearanceResetRetry")
                return
            end
            PatchAppearanceReset()
        end)
    end)
end
