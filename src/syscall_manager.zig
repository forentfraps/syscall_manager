const std = @import("std");
const syscall_lib = @import("syscall_wrapper.zig");
const winc = @import("Windows.h.zig");
const win = std.os.windows;

pub const syscall = syscall_lib.syscall;
const W = std.unicode.utf8ToUtf16LeStringLiteral;

const syscall_manager_error = error{
    SyscallMissing,
};

pub const SyscallManager = struct {
    _NtVirtualProtectMemorySyscall: ?syscall = null,
    _NtVirtualAllocateMemorySyscall: ?syscall = null,
    _NtOpenProcessSyscall: ?syscall = null,
    _NtWriteFileSyscall: ?syscall = null,
    _NtUserGetAsyncKeyStateSyscall: ?syscall = null,

    const Self = @This();

    pub fn addNTVPM(self: *Self, _syscall: syscall) void {
        self._NtVirtualProtectMemorySyscall = _syscall;
        return;
    }

    pub fn addNOP(self: *Self, _syscall: syscall) void {
        self._NtOpenProcessSyscall = _syscall;
        return;
    }

    pub fn addNWF(self: *Self, _syscall: syscall) void {
        self._NtWriteFileSyscall = _syscall;
    }

    pub fn addNTUGAKS(self: *Self, _syscall: syscall) void {
        self._NtUserGetAsyncKeyStateSyscall = _syscall;
    }

    pub fn NtUserGetAsyncKeyState(
        self: *Self,
        key: u32,
        numCallIdx: u32,
    ) usize {
        if (self._NtUserGetAsyncKeyStateSyscall == null) {
            return syscall_manager_error.SyscallMissing;
        }
        return self._NtUserGetAsyncKeyStateSyscall(
            @intCast(key),
            @intCast(numCallIdx),
        );
    }

    pub fn NtWriteFile(
        self: *Self,
        FileHandle: usize,
        Event: usize,
        ApcRoutive: usize,
        ApcContext: usize,
        IoStatusBlock: *win.IO_STATUS_BLOCK,
        Buffer: [*]const u8,
        Length: usize,
        ByteOffset: usize,
        Key: usize,
    ) !usize {
        if (self._NtWriteFileSyscall == null) {
            return syscall_manager_error.SyscallMissing;
        }

        return self._NtWriteFileSyscall.?.call(.{
            FileHandle,
            Event,
            ApcRoutive,
            ApcContext,
            @intFromPtr(IoStatusBlock),
            @intFromPtr(Buffer),
            Length,
            ByteOffset,
            Key,
        });
    }

    pub fn NtOpenProcess(
        self: *Self,
        ProcessHandle: *usize,
        DesiredAcess: usize,
        ObjectAttributes: *anyopaque,
        ClientId: *anyopaque,
    ) !usize {
        if (self._NtOpenProcessSyscall == null) {
            return syscall_manager_error.SyscallMissing;
        }

        return self._NtOpenProcessSyscall.?.call(.{
            @intFromPtr(ProcessHandle),
            DesiredAcess,
            @intFromPtr(ObjectAttributes),
            @intFromPtr(ClientId),
        });
    }

    pub fn NtVirtualProtectMemory(
        self: *Self,
        ProcessHandle: usize,
        PBaseAddress: *usize,
        NumberOfBytesToProtect: *usize,
        NewAccessProtection: usize,
        OldAccessProtection: *usize,
    ) !usize {
        if (self._NtVirtualProtectMemorySyscall == null) {
            return syscall_manager_error.SyscallMissing;
        }
        return self._NtVirtualProtectMemorySyscall.?.call(.{
            ProcessHandle,
            @intFromPtr(PBaseAddress),
            @intFromPtr(NumberOfBytesToProtect),
            NewAccessProtection,
            @intFromPtr(OldAccessProtection),
        });
    }

    pub fn NtAllocateVirtualMemory(
        self: *Self,
        BaseAddress: *?[*]u8,
        ZeroBits: usize,
        RegionSize: *usize,
        AllocationType: usize,
        Protect: usize,
    ) !usize {
        if (self._NtVirtualAllocateMemorySyscall == null) {
            return syscall_manager_error.SyscallMissing;
        }

        return self._NtVirtualAllocateMemorySyscall.?.call(.{
            @intFromPtr(BaseAddress),
            ZeroBits,
            @intFromPtr(RegionSize),
            AllocationType,
            Protect,
        });
    }
};
