// RUN: mlir-opt %s -test-spirv-cpu-runner-pipeline \
// RUN: | mlir-runner - -e main --entry-point-result=void --shared-libs=%mlir_runner_utils,%mlir_spirv_cpu_runtime --link-nested-modules \
// RUN: | FileCheck %s

// CHECK: [8,  8,  8,  8,  8,  8]
module attributes {
  gpu.container_module,
  spirv.target_env = #spirv.target_env<
    #spirv.vce<v1.0, [Shader], [SPV_KHR_variable_pointers]>,
    #spirv.resource_limits<
     max_compute_workgroup_invocations = 128,
     max_compute_workgroup_size = [128, 128, 64]>>
} {
  gpu.module @kernels {
    gpu.func @double(%arg0 : memref<6xi32>, %arg1 : memref<6xi32>)
      kernel attributes { spirv.entry_point_abi = #spirv.entry_point_abi<workgroup_size = [1, 1, 1]>} {
      %factor = arith.constant 2 : i32

      %i0 = arith.constant 0 : index
      %i1 = arith.constant 1 : index
      %i2 = arith.constant 2 : index
      %i3 = arith.constant 3 : index
      %i4 = arith.constant 4 : index
      %i5 = arith.constant 5 : index

      %x0 = memref.load %arg0[%i0] : memref<6xi32>
      %x1 = memref.load %arg0[%i1] : memref<6xi32>
      %x2 = memref.load %arg0[%i2] : memref<6xi32>
      %x3 = memref.load %arg0[%i3] : memref<6xi32>
      %x4 = memref.load %arg0[%i4] : memref<6xi32>
      %x5 = memref.load %arg0[%i5] : memref<6xi32>

      %y0 = arith.muli %x0, %factor : i32
      %y1 = arith.muli %x1, %factor : i32
      %y2 = arith.muli %x2, %factor : i32
      %y3 = arith.muli %x3, %factor : i32
      %y4 = arith.muli %x4, %factor : i32
      %y5 = arith.muli %x5, %factor : i32

      memref.store %y0, %arg1[%i0] : memref<6xi32>
      memref.store %y1, %arg1[%i1] : memref<6xi32>
      memref.store %y2, %arg1[%i2] : memref<6xi32>
      memref.store %y3, %arg1[%i3] : memref<6xi32>
      memref.store %y4, %arg1[%i4] : memref<6xi32>
      memref.store %y5, %arg1[%i5] : memref<6xi32>
      gpu.return
    }
  }
  func.func @main() {
    %input = memref.alloc() : memref<6xi32>
    %output = memref.alloc() : memref<6xi32>
    %four = arith.constant 4 : i32
    %zero = arith.constant 0 : i32
    %input_casted = memref.cast %input : memref<6xi32> to memref<?xi32>
    %output_casted = memref.cast %output : memref<6xi32> to memref<?xi32>
    call @fillI32Buffer(%input_casted, %four) : (memref<?xi32>, i32) -> ()
    call @fillI32Buffer(%output_casted, %zero) : (memref<?xi32>, i32) -> ()

    %one = arith.constant 1 : index
    gpu.launch_func @kernels::@double
        blocks in (%one, %one, %one) threads in (%one, %one, %one)
        args(%input : memref<6xi32>, %output : memref<6xi32>)
    %result = memref.cast %output : memref<6xi32> to memref<*xi32>
    call @printMemrefI32(%result) : (memref<*xi32>) -> ()
    return
  }

  func.func private @fillI32Buffer(%arg0 : memref<?xi32>, %arg1 : i32)
  func.func private @printMemrefI32(%ptr : memref<*xi32>)
}
