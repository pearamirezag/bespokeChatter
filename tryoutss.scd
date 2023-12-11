(
p = SerialPort(
    "/dev/tty.usbserial-A800crTT",    //edit to match your port. SerialPort.listDevices
    baudrate: 9600,    //check that baudrate is the same as in arduino sketch
    crtscts: true);
)

~servoBus = Bus.control(s, 1); // a single channel control bus on the default server

// this one expects to receive a trigger setter
(
SynthDef(\servoPos,{
	var pos;
	// trig = \trig.tr(0);
	pos = SinOsc.kr(\freq.kr(0.5));
	pos = Latch.kr(WhiteNoise.kr(),\trig.tr(0));
	pos = pos.lag(\lag.kr(1));
	Out.kr(~servoBus, pos.range(0,180))}
).add;
)

// this one is being triggered on the server
/*(
SynthDef(\servoPos,{
	var pos, trig;
	trig = Impulse.kr(\freq.kr(0.5));
	// pos = SinOsc.kr(\freq.kr(0.5));
	pos = Latch.kr(WhiteNoise.kr(),trig);
	pos = pos.lag(\lag.kr(1));
	Out.kr(~servoBus, pos.range(0,180))}
).add;
)*/

(
SynthDef(\test, {
	var snd, env;
	snd = SinOsc.ar();
	env = Env.adsr(0.01, 0.03, 0.7, 0.1).ar(Done.freeSelf, \trig.tr(1));
	snd = snd * env;
	Out.ar(\outbus.kr(0),snd.dup);
}).add;
)

i = Synth(\test);

x.set(\trig, 1, \lag,10.rand);
//send serial data - slow pulsating
(
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
)

~rServo.play;
~rServo.stop;
~rServo.class;

x.set(\freq, 1/2,\lag,1);

SendTrig

~rTrigPos.play;
~rTrigPos.(\speed, 0.5);

~rTrigPos.stop;


~servo.class

/// Routine for Triggering the change in position Servo
(
~rTrigPos = Routine.new({
	var dur;
    inf.do{
		dur = [2,10,0.5,4,7].wchoose([0.3,0.1,0.1,0.4,0.1]);
		~servSynth.set(\trig, 1, \lag,dur.rand);
		Synth(\test);
		dur.wait;
    };
});
)

r.stop;
p.close;





(
~rTrigPosFunc ={|v0 = 5, v1 = \stop|
	var r = Routine.new({
    inf.do{
		x.set(\trig, 1, \lag,10.rand);
		v0.rand.wait;
    };
		r.v1;
});
};
)

(
~rTrigPos = Routine{
    inf.do{
		x.set(\trig, 1, \lag,0.rand);
		2.wait;
    };
};
)



Symbol
ControlSpec