const std = @import("std");
const llvm = @import("llvm");
const Lexer = @import("Lexer.zig");
const target = llvm.target;
const types = llvm.types;
const core = llvm.core;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{});
    defer gpa.deinit();
    const allocator = gpa.allocator();

    var lexer: Lexer = Lexer.init(allocator, "");
    lexer.readChar();

    // _ = target.LLVMInitializeNativeTarget();
    // _ = target.LLVMInitializeNativeAsmPrinter();
    // _ = target.LLVMInitializeNativeAsmParser();
    //
    // const module: types.LLVMModuleRef = core.LLVMModuleCreateWithName("hello");
    // var params: [2]types.LLVMTypeRef = [_]types.LLVMTypeRef{
    //     core.LLVMInt32Type(),
    //     core.LLVMInt32Type(),
    // };
    //
    // // Create a function that computes the sum of two integers
    // const func_type: types.LLVMTypeRef = core.LLVMFunctionType(core.LLVMInt32Type(), &params, 2, 0);
    // const sum_func: types.LLVMValueRef = core.LLVMAddFunction(module, "sum", func_type);
    // const entry: types.LLVMBasicBlockRef = core.LLVMAppendBasicBlock(sum_func, "entry");
    // const builder: types.LLVMBuilderRef = core.LLVMCreateBuilder();
    // core.LLVMPositionBuilderAtEnd(builder, entry);
    // const arg1: types.LLVMValueRef = core.LLVMGetParam(sum_func, 0);
    // const arg2: types.LLVMValueRef = core.LLVMGetParam(sum_func, 1);
    // const sum: types.LLVMValueRef = core.LLVMBuildAdd(builder, arg1, arg2, "sum");
    // _ = core.LLVMBuildRet(builder, sum);
    //
    // // Dump the LLVM module to stdout
    // core.LLVMDumpModule(module);
    //
    // // Clean up LLVM resources
    // core.LLVMDisposeBuilder(builder);
    // core.LLVMDisposeModule(module);
    // core.LLVMShutdown();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
