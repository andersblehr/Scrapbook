Model subclass: #MyStateChart
	instanceVariableNames: 'state '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MyMinibank'!


!MyStateChart methodsFor: 'instance creation'!

initialize

	self state: #WaitForCard.! !

!MyStateChart methodsFor: 'accessing'!

state

	^state!

state: aState 

	state := aState.
	^self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MyStateChart class
	instanceVariableNames: ''!


!MyStateChart class methodsFor: 'instance creation'!

new

	^super new! !

MyStateChart subclass: #MyMinibank
	instanceVariableNames: 'message availableAmount keysReceived timesRepeated '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MyMinibank'!


!MyMinibank methodsFor: 'initialize-release'!

initialize

	super initialize.
	self timesRepeated: 0.
	self availableAmount: 200000.
	self displayMessage: '\\\  Velkommen til Mons'' Minibank!!\\        Sett inn kort i kortleser' withCRs.
	self keysReceived: '' asText.
	^self! !

!MyMinibank methodsFor: 'accessing'!

availableAmount

	^availableAmount!

availableAmount: newAmount 

	availableAmount := newAmount.
	^self!

keysReceived

	^keysReceived asText!

keysReceived: keys

	keysReceived := keys!

message

	^message!

message: aMessage
 
	message := aMessage.
	^self!

timesRepeated

	^timesRepeated!

timesRepeated: times

	timesRepeated := times! !

!MyMinibank methodsFor: 'displaying'!

displayMessage: aMessage 

	self message: aMessage.
	self changed: #message.
	^self!

doInsertMoney

	self displayMessage: '\\\\Legg pengene i innbetalingsluken!!' withCRs!

doInshot

	self displayMessage: '\\\Oppgi beloep: ' withCRs!

doPrintOut

	self displayMessage: '\\\          Saldo: ' withCRs, availableAmount printString, 
		'\\        Ta kontoutskrift!! ' withCRs!

doTakeMoney

	self displayMessage: '\\\\      Ta pengene!!' withCRs!

doTransaction

	self displayMessage: '\\\Oppgi kontonummer: ' withCRs!

doWithdrawal

	self displayMessage: '\\\Oppgi beloep (Tilgjengelig paa konto: ' withCRs,
		availableAmount printString, '): ' withCRs!

initialScreen

	self state: #WaitForCard.
	self keysReceived: '' asText.
	self displayMessage: '\\\  Velkommen til Mons'' Minibank!!\\        Sett inn kort i kortleser' withCRs.!

mainMenu

	self displayMessage: '\ Gjoer et valg i menyen:\\    F1: Uttak\    F2: Innskudd\    F3: Overfoering\    F4: Kontoutskrift\\    FEIL: Avslutt' withCRs!

output: something

	Transcript show: something asText! !

!MyMinibank methodsFor: 'updating'!

resetKeysReceived

	self keysReceived: '' asText!

updateAvailableAmount: sign
	
	sign == #neg ifTrue: [
		self availableAmount: self availableAmount - self keysReceived asNumber]
	ifFalse: [
		self availableAmount: self availableAmount + self keysReceived asNumber]! !

!MyMinibank methodsFor: 'verification'!

verifyCode

	keysReceived = '8671' asText ifTrue: [
		self timesRepeated: 0.
		^true]
	ifFalse: [
		self timesRepeated: self timesRepeated + 1.
		^false]!

verifyWithdrawal

	^(self keysReceived asNumber <= self availableAmount)! !

!MyMinibank methodsFor: 'actions'!

doActionOn: input with: optKey

	self output: state.
	state == #WaitForCard ifTrue: [
		input == #CardInserted ifTrue: [
			self state: #ReadCode.
			self readCode].
		^true].
	state == #ReadCode ifTrue: [
		input == #KeyPressed ifTrue: [
			self receiveKey: optKey.
			self displayMessage: self message, '*'].
		input == #Accepted ifTrue: [
			self verifyCode ifTrue: [
				self state: #MainMenu.
				self mainMenu]
			ifFalse: [
				self resetKeysReceived.
				self readCode]].
		input == #Canceled ifTrue: [
			self resetKeysReceived.
			self timesRepeated: 0.
			self readCode].
		^true].
	state == #MainMenu ifTrue: [
		input == #KeyPressed ifTrue: [
			optKey = 'F1' ifTrue: [
				self state: #Withdrawal.
				self resetKeysReceived.
				self doWithdrawal].
			optKey = 'F2' ifTrue: [
				self state: #Inshot.
				self resetKeysReceived.
				self  doInshot].
			optKey = 'F3' ifTrue: [
				self state: #Transaction.
				self resetKeysReceived.
				self  doTransaction].
			optKey = 'F4' ifTrue: [
				self state: #PrintOut.
				self resetKeysReceived.
				self  doPrintOut]].
		 input == #Canceled ifTrue: [
			self initialScreen].
		^true].
	state == #Withdrawal ifTrue: [
		input == #KeyPressed ifTrue: [	
			self receiveKey: optKey.
			self displayMessage: self message,  optKey].
		input == #Accepted ifTrue: [
			self verifyWithdrawal ifTrue: [
				self updateAvailableAmount: #neg.
				self resetKeysReceived.
				self state: #TakeMoney.
				self doTakeMoney]
			ifFalse: [
				self resetKeysReceived.
				self doWithdrawal]].
		input == #Canceled ifTrue: [
			self resetKeysReceived.
			self doWithdrawal].
		^true].
	state == #TakeMoney ifTrue: [
		input == #MoneyTaken ifTrue: [
			self state: #MainMenu.
			self resetKeysReceived.
			self mainMenu].
		^true].
	state == #Inshot ifTrue: [
		input == #KeyPressed ifTrue: [	
			self receiveKey: optKey.
			self displayMessage: self message,  optKey].
		input == #Accepted ifTrue: [
			self updateAvailableAmount: #pos.
			self resetKeysReceived.
			self state: #InsertMoney.
			self doInsertMoney].
		input == #Canceled ifTrue: [
			self resetKeysReceived.
			self doInshot].
		^true].
	state == #InsertMoney ifTrue: [
		input == #MoneyInserted ifTrue: [
			self state: #MainMenu.
			self resetKeysReceived.
			self mainMenu].
		^true].
	state == #Transaction ifTrue: [
		input == #KeyPressed ifTrue: [	
			self receiveKey: optKey.
			self displayMessage: self message,  optKey].
		input == #Accepted ifTrue: [
			self resetKeysReceived.
			self doWithdrawal.
			self state: #ReadAmount].
		input == #Canceled ifTrue: [
			self resetKeysReceived.
			self doTransaction].
		^true].
	state == #ReadAmount ifTrue: [
		input == #KeyPressed ifTrue: [	
			self receiveKey: optKey.
			self displayMessage: self message, optKey].
		input == #Accepted ifTrue: [
			self verifyWithdrawal ifTrue: [
				self updateAvailableAmount: #neg.
				self resetKeysReceived.
				self state: #MainMenu.
				self mainMenu]
			ifFalse: [
				self resetKeysReceived.
				self doWithdrawal]].
		input == #Canceled ifTrue: [
			self resetKeysReceived.
			self doWithdrawal].
		^true].
	state == #PrintOut ifTrue: [
		input == #PrintoutTaken ifTrue: [
			self state: #MainMenu.
			self mainMenu]].
	state == #WaitForAccept ifTrue: [
		input == #Accepted ifTrue: [
			self initialScreen]]!

readCode

	self timesRepeated = 3 ifFalse: [
		self displayMessage: '\\\Skriv kode: ' withCRs]
	ifTrue: [
		self displayMessage: '\\\  Kort svelget, kontakt banken!!' withCRs,
							  '\\              Trykk KLAR' withCRs.
		self timesRepeated: 0.
		self state: #WaitForAccept]!

receiveKey: aKey

	self keysReceived: self keysReceived, aKey! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MyMinibank class
	instanceVariableNames: ''!


!MyMinibank class methodsFor: 'instance creation'!

new

	^super new initialize!

open

	self open: self new.
	^self!

open: aMinibank 

	| window container screen
	button1 button2 button3 button4 button5
	button6 button7 button8 button9 button0 
	f1Button f2Button f3Button f4Button
	acceptButton cancelButton
	cardReader printer emitter absorber |

	(window := ScheduledWindow new) label: 'Mons'' Minibank'.
	window minimumSize: 400 @ 400.
	
	container := CompositePart new.

	screen := TextView
		on: aMinibank
		aspect: #message
		change: #message:
		menu: false.

	container
		add: screen
		in: (0.05 @ 0.05 corner: 0.6 @ 0.5)
		borderWidth: 2.

	"Numeric keys"

	button1 := MyKeyView openWithLabel: '1' on: aMinibank.
	button2 := MyKeyView openWithLabel: '2' on: aMinibank.
	button3 := MyKeyView openWithLabel: '3' on: aMinibank.
	button4 := MyKeyView openWithLabel: '4' on: aMinibank.
	button5 := MyKeyView openWithLabel: '5' on: aMinibank.
	button6 := MyKeyView openWithLabel: '6' on: aMinibank.
	button7 := MyKeyView openWithLabel: '7' on: aMinibank.
	button8 := MyKeyView openWithLabel: '8' on: aMinibank.
	button9 := MyKeyView openWithLabel: '9' on: aMinibank.
	button0 := MyKeyView openWithLabel: '0' on: aMinibank.

	container 
		add: button1 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.75; 
				topFraction: 0.05; 
				rightFraction: 0.8; 
				bottomFraction: 0.1).

	container 
		add: button2 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.825; 
				topFraction: 0.05; 
				rightFraction: 0.875; 
				bottomFraction: 0.1).
	
	container 
		add: button3 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.9; 
				topFraction: 0.05; 
				rightFraction: 0.95; 
				bottomFraction: 0.1).

	container 
		add: button4 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.75; 
				topFraction: 0.125; 
				rightFraction: 0.8; 
				bottomFraction: 0.175).

	container 
		add: button5 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.825; 
				topFraction: 0.125; 
				rightFraction: 0.875; 
				bottomFraction: 0.175).

	container 
		add: button6 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.9; 
				topFraction: 0.125; 
				rightFraction: 0.95; 
				bottomFraction: 0.175).

	container 
		add: button7 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.75; 
				topFraction: 0.2; 
				rightFraction: 0.8; 
				bottomFraction: 0.25).

	container 
		add: button8 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.825; 
				topFraction: 0.2; 
				rightFraction: 0.875; 
				bottomFraction: 0.25).

	container 
		add: button9 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.9; 
				topFraction: 0.2; 
				rightFraction: 0.95; 
				bottomFraction: 0.25).

	container 
		add: button0 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.75; 
				topFraction: 0.275; 
				rightFraction: 0.8; 
				bottomFraction: 0.325).

	"Accept button"

	(acceptButton := LabeledBooleanView new) beTrigger.
	acceptButton controller beTriggerOnUp.
	acceptButton label: ' KLAR'.
	acceptButton model: (
		(PluggableAdaptor on: aMinibank)
			getBlock: [:model | false]
			putBlock: [:model :value | model doActionOn: #Accepted with: nil]
			updateBlock: [:model :value :parameter | false]).

	container 
		add: acceptButton 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.825; 
				topFraction: 0.275; 
				rightFraction: 0.95; 
				bottomFraction: 0.325).

	"Cancel button"

	(cancelButton := LabeledBooleanView new) beTrigger.
	cancelButton controller beTriggerOnUp.
	cancelButton label: '     FEIL'.
	cancelButton model: (
		(PluggableAdaptor on: aMinibank)
			getBlock: [:model | false]
			putBlock: [:model :value | model doActionOn: #Canceled with: nil]
			updateBlock: [:model :value :parameter | false]).

	container 
		add: cancelButton 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.75; 
				topFraction: 0.35; 
				rightFraction: 0.95; 
				bottomFraction: 0.4).

	"Function keys"

	f1Button := MyKeyView openWithLabel: 'F1' on: aMinibank.
	f2Button := MyKeyView openWithLabel: 'F2' on: aMinibank.
	f3Button := MyKeyView openWithLabel: 'F3' on: aMinibank.
	f4Button := MyKeyView openWithLabel: 'F4' on: aMinibank.

	container 
		add: f1Button 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.625; 
				topFraction: 0.05; 
				rightFraction: 0.725; 
				bottomFraction: 0.1).

	container 
		add: f2Button 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.625; 
				topFraction: 0.125; 
				rightFraction: 0.725; 
				bottomFraction: 0.175).

	container 
		add: f3Button 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.625; 
				topFraction: 0.2; 
				rightFraction: 0.725; 
				bottomFraction: 0.25).

	container 
		add: f4Button 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.625; 
				topFraction: 0.275; 
				rightFraction: 0.725; 
				bottomFraction: 0.325).

	"Card reader"

	(cardReader := LabeledBooleanView new) beTrigger.
	cardReader controller beTriggerOnUp.
	cardReader label: '      KORTLESER'.
	cardReader model: (
		(PluggableAdaptor on: aMinibank)
			getBlock: [:model | false]
			putBlock: [:model :value | model doActionOn: #CardInserted with: nil]
			updateBlock: [:model :value :parameter | false]).

	container 
		add: cardReader 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.625; 
				topFraction: 0.6; 
				rightFraction: 0.95; 
				bottomFraction: 0.65).

	"Printer"

	(printer := LabeledBooleanView new) beTrigger.
	printer controller beTriggerOnUp.
	printer label: '  UTSKRIFTSENHET'.
	printer model: (
		(PluggableAdaptor on: aMinibank)
			getBlock: [:model | false]
			putBlock: [:model :value | model doActionOn: #PrintoutTaken with: nil]
			updateBlock: [:model :value :parameter | false]).

	container 
		add: printer 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.625; 
				topFraction: 0.8; 
				rightFraction: 0.95; 
				bottomFraction: 0.85).

	"Emitter"

	(emitter := LabeledBooleanView new) beTrigger.
	emitter controller beTriggerOnUp.
	emitter label: '       UTBETALINGSLUKE'.
	emitter model: (
		(PluggableAdaptor on: aMinibank)
			getBlock: [:model | false]
			putBlock: [:model :value | model doActionOn: #MoneyTaken with: nil]
			updateBlock: [:model :value :parameter | false]).

	container 
		add: emitter 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.05; 
				topFraction: 0.6; 
				rightFraction: 0.5; 
				bottomFraction: 0.65).

	"Absorber"

	(absorber := LabeledBooleanView new) beTrigger.
	absorber controller beTriggerOnUp.
	absorber label: '      INNBETALINGSLUKE'.
	absorber model: (
		(PluggableAdaptor on: aMinibank)
			getBlock: [:model | false]
			putBlock: [:model :value | model doActionOn: #MoneyInserted with: nil]
			updateBlock: [:model :value :parameter | false]).

	container 
		add: absorber 
		borderedIn: (
			(LayoutFrame new) 
				leftFraction: 0.05; 
				topFraction: 0.8; 
				rightFraction: 0.5; 
				bottomFraction: 0.85).

	"Open window"

	window component: container.
	window open.

	^self! !

LabeledBooleanView subclass: #MyKeyView
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'MyMinibank'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MyKeyView class
	instanceVariableNames: ''!


!MyKeyView class methodsFor: 'instance creation'!

new

	^super new!

openWithLabel: aLabel on: aModel 

	| button |

	(button := self new) beTrigger.
	button controller beTriggerOnUp.
	button label: aLabel.
	button model: ((PluggableAdaptor on: aModel)
			getBlock: [:model | false]
			putBlock: [:model :value | model doActionOn: #KeyPressed with: aLabel ]
			updateBlock: [:model :value :parameter | false]).
	^button! !
