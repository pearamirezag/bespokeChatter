// https://www.youtube.com/watch?v=9yoAGbs2eJ8



(
~path = PathName(thisProcess.nowExecutingPath).parentPath ++ "sounds";
~src = Buffer.readChannel(s, ~path,channels:0);
)

~src.play;

(
~indices = Buffer(s);
FluidBufOnsetSlice.processBlocking(s,~src,metric:9,threshold:0.7,indices:~indices,action:{"done".postln});
)

(
~indices = Buffer(s);
FluidBufNoveltySlice.processBlocking(s,~src,
	algorithm: 1,
	threshold:0.4,
	indices:~indices,
	minSliceLength: 2*4,
	action:{
		"done".postln});
)

~indices.postln;

(
~indices.loadToFloatArray(action:{
	arg fa;
	fa.postln;
	fa.size.postln;
});
)

FluidWaveform(~src,~indices);

(
~play_slice = {
	arg index;
	{
		var startsamp = Index.kr(~indices,index);
		var stopsamp = Index.kr(~indices,index+1);
		var phs = Phasor.ar(0,BufRateScale.ir(~src),startsamp,stopsamp);
		var sig = BufRd.ar(1,~src,phs);
		var dursecs = (stopsamp - startsamp) / BufSampleRate.ir(~src);
		var env = EnvGen.kr(Env([0,1,1,0],[0.03,dursecs-0.06,0.03]),doneAction:2);
		sig.dup * env;
	}.play;
}
)


(
fork{
	( ~indices.numFrames - 1).do{
		arg i;
		~play_slice.(i);
		i.postln;
		0.4.wait;
	};
}
)


//analysis

(
~indices.loadToFloatArray(action:{
	arg fa;
	var spec = Buffer(s);
	var stats = Buffer(s);
	var meancentroids = Buffer(s);

	fa.doAdjacentPairs{
		arg start, end, i;
		var num = end - start;
		start.postln;
		end.postln;
		i.postln;
		"".postln;

		FluidBufSpectralShape.processBlocking(s, ~src, start, num, features:spec, select: [\centroid]);
		FluidBufStats.processBlocking(s,spec,stats:stats,select:[\mean]);
		FluidBufCompose.processBlocking(s,stats,destination:meancentroids,destStartFrame:i);
		s.sync;

		spec.loadToFloatArray(action:{
			arg fa;
			fa.postln;
			stats.postln;

		});

		"".postln;

		s.sync;
	};

};)
)






(
~indices.loadToFloatArray(action:{
	arg fa;
	var spec = Buffer(s);
	var stats = Buffer(s);
	var meancentroids = Buffer(s);

	fa.doAdjacentPairs{
		arg start, end, i;
		var num = end - start;
		start.postln;
		end.postln;
		i.postln;
		"".postln;

		FluidBufSpectralShape.processBlocking(s, ~src, start, num, features:spec, select: [\centroid]);
		FluidBufStats.processBlocking(s,spec,stats:stats,select:[\mean]);
		FluidBufCompose.processBlocking(s,stats,destination:meancentroids,destStartFrame:i);
		};

		s.sync;

		meancentroids.loadToFloatArray(action:{
			arg fa;
			fa.postln;
			fa.size.postln;
		~meancentroids = fa;
		}
		);
};)
)

~meancentroids.postln;
~order = ~meancentroids.order;


(
fork{
	~order.do{
		arg i;
		"playing slice: %".format(i).postln;
		~play_slice.(i);
		0.3.wait;
	};
}
)
