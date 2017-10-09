TemplateScrollComponent = require "template-cell-scrollcomponent/TemplateScrollComponent"
InputModule = require "input-framer/input"
firebase = require("npm").firebase
{firebase} = require "npm"
swing = require("npm").swing
{swing} = require "npm"
cookies = require("npm").cookies
{cookies} = require "npm"

#Config : Firebase

config = {
  apiKey: "AIzaSyBGxKjq3p6A5GnzDjMAcnSeHjiPZDVI2RE",
  authDomain: "archinder-a01.firebaseapp.com",
  databaseURL: "https://archinder-a01.firebaseio.com",
  storageBucket: "archinder-a01.appspot.com",
};

try 
	firebase.initializeApp(config);database = firebase.database();
	storage = firebase.storage();
	provider = new firebase.auth.FacebookAuthProvider();
	provider.addScope('user_birthday');
	#provider.addScope('user_education_history');
	provider.addScope('user_location');
catch e then print "nope :" + e


#Config : Enviroment
tracksUser = {};
cards = {};
uid = null;

getRandomInt = (min, max) ->
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min)) + min; 

randomString = (len) ->
	text = " ";
	charset = "abcdefghijklmnopqrstuvwxyz0123456789";
	for i in [0..len]
		text += charset.charAt(Math.floor(Math.random() * charset.length));
	return text;

#Function : Process track data to UI

populateTrackList = ( data ) ->
	dataFormatter =
		unit: ( val ) -> val.toLowerCase()
	tracks = new TemplateScrollComponent
		wrap: containerTracks
		backgroundColor: null
		scrollHorizontal: false
		numberOfItems: data.length
		templateItem: trackItemTemplate
	# Original template layer will destroyed from hierarchy
	tracks.content.addChild trackItemTemplate
	tracks.forItemAtIndex = ( index, layer ) ->
		cell = layer.copy()
		if data[index].active
			cell.children[1].backgroundColor = "#66BB66"
		else 
			cell.children[1].backgroundColor = "#EE4444"
		TemplateScrollComponent.applyTemplate cell, data[ index ], dataFormatter
		return cell
#Function : Load cards data
populateCards = ( tracksUser ) ->
	for index in [0..tracksUser.length-1]
		if tracksUser[index].active
			database.ref("tracks/"+tracksUser[index].name).once("value").then( (data) ->
				for index in [0..data.val().length-1]
					cardName =  data.val()[index]
					database.ref("cards/"+cardName).once("value").then( (data) ->
						id = data.val().id
						newCard = card.copy();
						cards[id] = newCard;
						cards[id].data = data.val();
						cards[id].animate
							options:
								time: 0.3
								curve: Bezier.ease #Swiping Screen : Cards
						cards[id].states.visible =
							opacity: 1.00
						cards[id].states.like =
							x: 440
							y: 200
							rotation:40
							opacity: 1.00
						cards[id].states.dislike =
							x: -440
							y: 200
							rotation:-40
							opacity: 1.00
						screenSwiping.addChild(cards[id])
						imageRef = storage.ref(data.val().imagePath);
						imageRef.getDownloadURL().then( (url) ->
							start = url.indexOf("%2F") + 3
							end = url.indexOf(".jpg")
							id =  url.substring(start,end)
							cards[id].data.imageUrl = url
							cards[id].children[0].image = url
							)
					)
				)
#Firebase : User Init, User Login, DB Init
firebase.auth().onAuthStateChanged( (user) ->
	if user 
		#User is signed in.
		displayName = user.displayName;
		email = user.email;
		photoURL = user.photoURL;
		uid = user.uid;
		providerData = user.providerData;
		#save user details to db
		database.ref("users/"+uid+"/displayName").set({ "value":displayName})
		database.ref("users/"+uid+"/email").set({ "value":email})
		database.ref("users/"+uid+"/photoURL").set({ "value":photoURL})
		#Login actions
		imgUser.image = photoURL;
		radarUserImage.image = photoURL;
		txtName.text = displayName
		#attach a listener for the tracks (This is async!)
		database.ref("users/"+uid+"/tracks").once("value").then( (data) ->
			if !data.val()
				database.ref("users/default/tracks").once("value").then( (data) -> 
					tracksUser = data.val()
					firebase.database().ref("users/"+uid+"/tracks").set({ "value":tracksUser})
					populateTrackList(tracksUser)
					populateCards(tracksUser)
				)
			else
				tracksUser = data.val().value
				populateTrackList(tracksUser)
				populateCards(tracksUser)
		)
		flow.showNext(screenSettings)
	else
		flow.showNext(screenLogin)
)

firebase.auth().getRedirectResult().then( (result) ->
	if (result.credential)
		token = result.credential.accessToken;
	uid = result.user.uid;
	path = "users/" + uid;
	addInfo = result.additionalUserInfo;
	database.ref(path + "/birthday").set({ "value":addInfo.profile.birthday})
	database.ref(path + "/location/name").set({ "value":addInfo.profile.location.name})
	database.ref(path + "/location/id").set({ "value":addInfo.profile.location.id})
	).catch( (error) ->
		errorCode = error.code;
		errorMessage = error.message;
		email = error.email;
		credential = error.credential;
	);

# General Framer setup
flow = new FlowComponent
flow.showNext(screenLogin)

#Login Screen

coverflow = new PageComponent
    width: containerCoverflow.width
    height: containerCoverflow.height
    scrollVertical: false
containerCoverflow.addChild(coverflow)
coverflowLogo.width = containerCoverflow.width
coverflowCards1.width = containerCoverflow.width
coverflow.addPage(coverflowLogo)
coverflow.addPage(coverflowCards1,"right")


login = new FlowComponent
containerLogin.addChild(login)
login.showNext(loginChoice)

btnWelcomeLoginFacebook.onTap (event, layer) ->
	btnWelcomeLoginFacebookText.text = "...loading..."
	btnWelcomeLoginEmail.visible = false;
	firebase.auth().signInWithRedirect(provider);
	

inputEmail = new InputModule.Input
	virtualKeyboard: false 
	placeholder: "email" 
	placeholderColor: "#CFCFD3"
	textColor: "#8E8E93"
	fontSize: 14
	width: 300
	height: 20
inputPassword = new InputModule.Input
	virtualKeyboard: false 
	type: "password"
	placeholder: "password" 
	placeholderColor: "#CFCFD3"
	textColor: "#8E8E93"
	fontSize: 14
	width: 300
	height: 20

txtEmail.addChild(inputEmail)
inputEmail.value = "burger@meso.net"
txtPass.addChild(inputPassword)
inputPassword.value = "poopCat!"

btnWelcomeLoginEmail.onTap (event, layer ) ->
	login.showNext(loginEmail)


btLoginEmailBack.onTap (event, layer) ->
	login.showPrevious(loginChoice)

btLoginEmailSignup.onTap (event, layer) ->
	firebase.auth().createUserWithEmailAndPassword(inputEmail.value, inputPassword.value)

btLoginEmailLogin.onTap (event, layer) ->
	firebase.auth().signInWithEmailAndPassword(inputEmail.value, inputPassword.value)

#Settings screen : Nav Bar
btnLogoutConfirm.states.a =
	opacity: 100
btnLogoutConfirm.states.b =
	opacity: 0
logout.states.a =
	x: -120
logout.states.b =
	x: 20
	
logout.animate
	options:
		time: 0.3
		curve: Bezier.ease
	
btnLogoutConfirm.animate
	options:
		time: 0.3
		curve: Bezier.ease
logout.stateSwitch("a")

btnLogoutConfirm.onTap (event, layer) ->
	logout.stateSwitch("b")
	btnLogoutConfirm.stateSwitch("b")

btnDontLogout.onTap (event, layer) ->
	logout.stateSwitch("a")
	btnLogoutConfirm.stateSwitch("a")


btnLogout.onTap (event, layer) ->
	logout.stateSwitch("a")
	btnLogoutConfirm.stateSwitch("a")
	firebase.auth().signOut()
	flow.showPrevious(screenLogin)

btnGoSwipe.onTap (event, layer) ->
	flow.showNext(screenSwiping)

#Settings screen : Tracks
#Swiping screen : Pulseing
#Stopping timers : https://www.facebook.com/photo.php?fbid=326160497580950&set=p.326160497580950&type=3&theater&ifg=1
radarPulseTimer = null
radarPulseTime = 3;
radarPulseAnimation = new Animation
	layer: radarPulse
	properties: 
		scale: 6
		blur: 100
	curve: "linear"
	time: radarPulseTime

radarPulseAnimationStop = () ->
	radarPulseTimer && window.clearInterval radarPulseTimer
	radarPulseTimer = null

radarPulseAnimationStart = () ->
	radarPulseTimer = radarPulseTimer or Utils.interval radarPulseTime, ->
		radarPulse.scale = 0.5
		radarPulse.blur = 0
		radarPulseAnimation.start()

radarPulseAnimationStart()

btnSettings.onTap (event, layer) ->
	flow.showPrevious(screenSettings)



#Swiping Screen : Cards
randomRotation = () ->
	if getRandomInt(-11,10) > 0
		return getRandomInt(2,4)
	else 
		return getRandomInt(-4,-2)

manageCards = () ->
	keys = Object.keys(cards)
	if keys.length > 0
		cardAddTimerStop()
		cards[keys[0]].opacity = 0;
		cards[keys[0]].visible = true;
		cards[keys[0]].animate("visible")
		btnLike.animate("a")
		btnDislike.animate("a")
		if keys.length > 1
			cards[keys[1]].placeBehind(cards[keys[0]])
			cards[keys[1]].rotation = randomRotation()
			cards[keys[1]].visible = true;
		else
			#print "Last card"
	else
		cardAddTimerStart();

cardAddTimer = null
cardAddTimerTime = 3;

cardAddTimerStop = () ->
	cardAddTimer && window.clearInterval cardAddTimer
	cardAddTimer = null

cardAddTimerStart = () ->
	cardAddTimer = cardAddTimer or Utils.interval cardAddTimerTime, ->
		manageCards()

cardAddTimerStart()

logResult = (cardID, choice) ->
	data = {
		"user": uid,
		"card": cardID,
		"choice": choice,
		"time" : Date.now()
		}
	database.ref("swipes/"+uid+"/" + randomString(15) ).set(data)



	
btnLike.animate
	options:
		time: 0.3
		curve: Bezier.ease #Swiping Screen : Cards
btnDislike.animate
	options:
		time: 0.3
		curve: Bezier.ease #Swiping Screen : Cards
		
btnDislike.states.a =
	opacity: 1.00
btnDislike.states.b =
	opacity: 0
	
btnLike.animate
	options:
		time: 0.3
		curve: Bezier.ease #Swiping Screen : Cards
		
btnLike.states.a =
	opacity: 1.00
btnLike.states.b =
	opacity: 0
	

doSwipe  = (choice) ->
	keys = Object.keys(cards)
	cards[keys[0]].animate(choice)
	#cards[keys[0]].visible = false;
	logResult(cards[keys[0]].data.id, choice)
	if keys.length == 1
		btnLike.animate("b")
		btnDislike.animate("b")
		#btnDislike.visible = false;
		#btnLike.visible = false;
	if keys.length == 2
		#print "Showing last card " + cards[keys[1]].data.id
		cards[keys[1]].rotation = randomRotation()
		cards[keys[1]].opacity = 0;
		cards[keys[1]].animate("visible")
		cards[keys[1]].visible = true;
	if keys.length > 2
		#print "Showing card " + cards[keys[2]].data.id
		cards[keys[2]].placeBehind( cards[keys[1]] )
		cards[keys[2]].rotation = randomRotation()
		cards[keys[2]].opacity = 0;
		cards[keys[2]].animate("visible")
		cards[keys[2]].visible = true;
	delete cards[keys[0]]


#Swiping Screen : Buttons
btnLike.onTap (event, layer) ->
	doSwipe("like")
btnDislike.onTap (event, layer) ->
	doSwipe("dislike")
btnSettings.onTap (event, layer) ->
	#print "To settings"
	flow.showPrevious(screenSettings)

