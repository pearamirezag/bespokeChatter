(

	// to do
	// change audio interface
	// change arduino serial port
	// 

s.options.numOutputBusChannels = 16;
s.options.numInputBusChannels = 2;
s.options.numPrivateAudioBusChannels = 1024;
s.options.numWireBufs = 1024;
s.options.memSize = 2.pow(20);
s.options.sampleRate = 44100;
s.options.blockSize = 64;

//change to the fireface

// s.options.outDevice_("X-USB");
// s.options.inDevice_("X-USB");

Server.default.waitForBoot {
	// Initialize Serial Port

	(
p = SerialPort(
    "/dev/tty.usbserial-A800crTT",    //edit to match your port. SerialPort.listDevices
    baudrate: 9600,    //check that baudrate is the same as in arduino sketch
    crtscts: true);
)
	~servoBus = Bus.control(s, 1); // a single channel control bus on the default server


	/////////////////////////////////////////////////////////////////////////////
	////////////////////////// Synth Defs ///////////////////////////////////////


	//SynthDef to write values to the Servo
	(
		SynthDef(\servoPos,{
			var pos;
			// trig = \trig.tr(0);
			// pos = SinOsc.kr(\freq.kr(0.5));
			pos = Latch.kr(WhiteNoise.kr(),\trig.tr(0));
			pos = pos.lag(\lag.kr(1));
			Out.kr(~servoBus, pos.range(0,180))}
		).add;
	)

    SynthDef(\sine, {
        var snd;
        snd = SinOsc.ar(\freq.kr(440));
        snd = snd * Env.perc(0.01, 0.3).ar(Done.freeSelf);
        Out.ar(0, snd);
    }).add;

	"added synthDefs".postln;

	/////////////////////////////////////////////////////////////////////////////
	////////////////////////// R o u t i n e s ////////////////////////////////// 


	// Routine for sending the values to the servomotor
	~rServo = Routine.new({
		~servSynth = Synth(\servoPos);
		inf.do{
	
			~servoBus.get({arg val;
				// p.put(val)
				val = val.ceil.asInteger;
				val.postln;
			}); //ask for the bus' value from the language
			0.05.wait;
		};
	});

	//Routine for triggering the sounds and server movements

	~rTrigPos = Routine.new({
		var dur;
		inf.do{
			dur = [2,10,0.5,4,7].wchoose([0.3,0.1,0.1,0.4,0.1]);
			~servSynth.set(\trig, 1, \lag,dur.rand);
			Synth(\test);
			dur.wait;
		};
	});

	"added Routines".postln;
	
    Server.default.sync;
	
	~rServo.play;
	~rTrigPos.play;

	"done".postln;

}; // wait for boot

) // big