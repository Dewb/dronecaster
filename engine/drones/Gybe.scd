
(
a = SynthDef("gybe",
	{
		arg hz=65.41, amp=0.5;

		var heart, tubes, gears;
		var fear, hope, regret, desire;
		var hiss, rumble;
		var blue, black, white;

		var buffers, strings, snd;
		var gates, pitches, feedback;

		heart = Plorenz(10, 28, 2.667, 0.01, 0.090879, 2.97, 24.282).asStream;
		tubes = Plorenz().asStream;
		gears = Plorenz().asStream;

		{
			loop {
				#x, y, z = heart.next;
				blue = y * 600;
				1.wait;
			}
		}.fork;

		buffers = 4.collect({LocalBuf.new(8192,1)});
		gates = 4.collect({ToggleFF.kr(Dust.kr(2.3) + Impulse.kr(0))});

		feedback = 0.021;

		// LocalIn gathers our string players (below)
		snd = 0.7 * LocalIn.ar(2) + PinkNoise.ar(0.02) + WhiteNoise.ar(0.001);

		// Reverb
		snd = FreeVerb.ar(snd, 0.27, 1.0, 0.0, 1.2);

		// Comb filter delay
		snd = 0.7 * snd + 0.5 * Mix.ar(
			Array.fill(7, { CombL.ar(snd, 0.3, LFNoise1.kr(0.3.rand, 0.04, 0.05), 0.8) })
		);
		snd.softclip;

		// All pass smear
		4.do({ snd = AllpassN.ar(snd, 0.050, [0.050.rand, 0.050.rand], 1) });
		snd.softclip;

		snd = snd * 1.0;

		// And we're done
		Out.ar(0, snd);

		// Finally, feed some pitch-shifted output back to the string bus
		LocalOut.ar(0.5 * PitchShift.ar(snd, 0.2, -5.midiratio, 0.06, 0.01, feedback));

		// -----------------------------------------------------------------
		// String simulation adapted from Eli Fieldsteel's SuperCollider
		// recreation of Pietro Mascagni's 'Cavalleria rusticana'
		// http://sccode.org/1-5do
		// -----------------------------------------------------------------

		//wavetables based on spectral analysis of orchestral instruments
		//cello 1
		~wt0 = Signal.sineFill(
			4096,
			([
				-12, -3, -21, -18, -24,
				-15, -18, -21, -18, -24,
				-27, -33, -27, -30, -30,
				-30, -30, -40, -90, -33,
				-40, -30, -27, -40, -33
			].dbamp ++
			(26..300).reciprocal.pow(1.8)) *
			((1!25) ++ ({exprand(1/4,4)}!275)),
			{rrand(0,2pi)}!300
		).asWavetable;
		buffers[0].set(~wt0);

		//cello 2
		~wt1 = Signal.sineFill(
			4096,
			([
				-3, -6, -18, -36, -9,
				-24, -24, -27, -24, -40,
				-24, -21, -36, -40, -33,
				-36, -40, -33, -39, -40
			].dbamp ++
			(21..90).reciprocal.pow(1.9)) *
			((1!20) ++ ({exprand(1/3,3)}!70)),
			{rrand(0,2pi)}!90
		).asWavetable;
		buffers[1].set(~wt1);

		//viola
		~wt2 = Signal.sineFill(
			4096,
			([
				-3, -9, -6, -9, -18,
				-9, -15, -12, -15, -18,
				-15, -40, -24, -21, -30,
				-33, -33, -36, -30, -36
			].dbamp ++
			(21..60).reciprocal.pow(1.9)) *
			((1!20) ++ ({exprand(1/3,3)}!40)),
			{rrand(0,2pi)}!60
		).asWavetable;
		buffers[2].set(~wt2);

		//violin
		~wt3 = Signal.sineFill(
			4096,
			([
				-3, -6, -15, -9, -15,
				-12, -12, -24, -30, -24,
				-33, -27, -33, -33, -36,
				-40, -36, -36, -40, -40
			].dbamp ++
			(21..40).reciprocal.pow(2)) *
			((1!20) ++ ({exprand(1/3,3)}!20)),
			{rrand(0,2pi)}!40
		).asWavetable;
		buffers[3].set(~wt3);

		4.collect({|i|
			var buf=buffers[i],
			freq=hz * [-24,-7,-12,0][i].midiratio,
			phs=0, detune=0.07,
			vibHz=12, vibPhs=0, vibDepth=0.2, vibFadeIn=2,
			atk=0.2, sus=0.01, rel=2, c0=1, c1=(-1),
			gate=gates[i],
			localamp=0.16 + 0.004*i,
			lpf=20000, lsf=150, ldb=4,
			pan=0;

			var sig, vibEnv, vibHzRand, detuneSig, env;

			env = EnvGen.kr(Env.new([0,1,0.8,0],[atk,sus,rel],[c0,0,c1],1), gate);
			sig = 12.collect({
				detuneSig = LFNoise1.kr(Rand(0.05,0.1)).bipolar(detune).midiratio;
				vibHzRand = LFNoise1.kr(Rand(0.15,0.3)).exprange(5/6,6/5);
				vibEnv = SinOsc.kr(vibHz * vibHzRand, vibPhs).bipolar(vibDepth);
				vibEnv = vibEnv * EnvGen.kr(Env.new([0,1],[vibFadeIn],[1]));
				vibEnv = vibEnv.midiratio;
				Osc.ar(
					buf,
					Lag.kr(freq, 3.1 + i * 0.65) * detuneSig * vibEnv,
					Rand(0.0,1.0)
				);
			});
			sig = Splay.ar(sig) * env;
			sig = LPF.ar(sig, lpf);
			sig = BLowShelf.ar(sig, lsf, 1, ldb);
			sig = Balance2.ar(sig[0], sig[1], pan, localamp);
			LocalOut.ar(sig);
		});
	}
).play;
)

a.set("hz", 65.41);
a.set("hz", 65.41*5.midiratio);
a.set("hz", 65.41*2);
a.set("hz", 65.41*2*5.midiratio);
a.set("hz", 34.midicps);
a.set("hz", 34.midicps * 5.midiratio);
a.set("hz", 75.midicps);

a.set("amp", 0.05); 