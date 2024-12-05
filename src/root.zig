const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("tts.h");
});

pub const Backend = enum(c.Backends) {
    Tolk = c.BACKENDS_TOLK,
    WinRt = c.BACKENDS_WIN_RT,
    SpeechDispatcher = c.BACKENDS_SPEECH_DISPATCHER,
    AppKit = c.BACKENDS_APP_KIT,
    AvFoundation = c.BACKENDS_AV_FOUNDATION,
    Android = c.BACKENDS_ANDROID,
    Web = c.BACKENDS_WEB,

    pub fn available(backend: Backend) bool {
        return switch (backend) {
            .Tolk, .WinRt => builtin.target.os.tag == .windows,
            .SpeechDispatcher => builtin.target.os.tag == .linux,
            .AppKit, .AvFoundation => builtin.target.os.tag == .macos,
            .Android => builtin.target.os.tag == .android,
            .Web => builtin.target.os.tag == .wasm,
        };
    }
};

pub const Features = struct {
    is_speaking: bool,
    pitch: bool,
    rate: bool,
    stop: bool,
    utterance_callbacks: bool,
    voice: bool,
    get_voice: bool,
    volume: bool,
};

pub const TtsError = error{
    InitializationFailed,
    InvalidOperation,
    UnsupportedFeature,
    OutOfMemory,
};

pub const UtteranceId = struct {
    id: *c.UtteranceId,

    pub fn deinit(self: UtteranceId) void {
        c.tts_free_utterance(self.id);
    }
};

pub const Tts = struct {
    tts: *c.Tts,

    pub fn init(backend_type: Backend) !Tts {
        if (!backend_type.available()) {
            return TtsError.UnsupportedFeature;
        }

        const tts = c.tts_new(backend_type) orelse {
            const err_msg = std.mem.span(c.tts_get_error());
            std.log.err("TTS initialization failed: {s}", .{err_msg});
            return TtsError.InitializationFailed;
        };

        return Tts{ .tts = tts };
    }

    pub fn initDefault() !Tts {
        const tts = c.tts_default() orelse {
            const err_msg = std.mem.span(c.tts_get_error());
            std.log.err("TTS initialization failed: {s}", .{err_msg});
            return TtsError.InitializationFailed;
        };

        return Tts{ .tts = tts };
    }

    pub fn deinit(self: *Tts) void {
        c.tts_free(self.tts);
    }

    pub fn supportedFeatures(self: *const Tts) Features {
        var features: c.Features = undefined;
        c.tts_supported_features(self.tts, &features);
        return .{
            .is_speaking = features.is_speaking,
            .pitch = features.pitch,
            .rate = features.rate,
            .stop = features.stop,
            .utterance_callbacks = features.utterance_callbacks,
            .voice = features.voice,
            .get_voice = features.get_voice,
            .volume = features.volume,
        };
    }

    pub fn speak(self: *Tts, text: [:0]const u8, interrupt: bool) !void {
        const success = c.tts_speak(self.tts, text.ptr, interrupt, null);
        if (!success) {
            const err_msg = std.mem.span(c.tts_get_error());
            std.log.err("TTS speak failed: {s}", .{err_msg});
            return TtsError.InvalidOperation;
        }
    }

    pub fn stop(self: *Tts) !void {
        if (!c.tts_stop(self.tts)) {
            const err_msg = std.mem.span(c.tts_get_error());
            std.log.err("TTS stop failed: {s}", .{err_msg});
            return TtsError.InvalidOperation;
        }
    }

    pub const RateRange = struct {
        min: f32,
        max: f32,
        normal: f32,
    };

    pub fn getRateRange(self: *const Tts) RateRange {
        return .{
            .min = c.tts_min_rate(self.tts),
            .max = c.tts_max_rate(self.tts),
            .normal = c.tts_normal_rate(self.tts),
        };
    }

    pub fn getRate(self: *const Tts) !f32 {
        var rate: f32 = undefined;
        if (!c.tts_get_rate(self.tts, &rate)) {
            return TtsError.UnsupportedFeature;
        }
        return rate;
    }

    pub fn setRate(self: *Tts, rate: f32) !void {
        if (!c.tts_set_rate(self.tts, rate)) {
            return TtsError.UnsupportedFeature;
        }
    }

    pub const PitchRange = struct {
        min: f32,
        max: f32,
        normal: f32,
    };

    pub fn getPitchRange(self: *const Tts) PitchRange {
        return .{
            .min = c.tts_min_pitch(self.tts),
            .max = c.tts_max_pitch(self.tts),
            .normal = c.tts_normal_pitch(self.tts),
        };
    }

    pub fn getPitch(self: *const Tts) !f32 {
        var pitch: f32 = undefined;
        if (!c.tts_get_pitch(self.tts, &pitch)) {
            return TtsError.UnsupportedFeature;
        }
        return pitch;
    }

    pub fn setPitch(self: *Tts, pitch: f32) !void {
        if (!c.tts_set_pitch(self.tts, pitch)) {
            return TtsError.UnsupportedFeature;
        }
    }

    pub const VolumeRange = struct {
        min: f32,
        max: f32,
        normal: f32,
    };

    pub fn getVolumeRange(self: *const Tts) VolumeRange {
        return .{
            .min = c.tts_min_volume(self.tts),
            .max = c.tts_max_volume(self.tts),
            .normal = c.tts_normal_volume(self.tts),
        };
    }

    pub fn getVolume(self: *const Tts) !f32 {
        var volume: f32 = undefined;
        if (!c.tts_get_volume(self.tts, &volume)) {
            return TtsError.UnsupportedFeature;
        }
        return volume;
    }

    pub fn setVolume(self: *Tts, volume: f32) !void {
        if (!c.tts_set_volume(self.tts, volume)) {
            return TtsError.UnsupportedFeature;
        }
    }

    pub fn isSpeaking(self: *const Tts) !bool {
        var speaking: bool = undefined;
        if (!c.tts_is_speaking(self.tts, &speaking)) {
            return TtsError.UnsupportedFeature;
        }
        return speaking;
    }
};
