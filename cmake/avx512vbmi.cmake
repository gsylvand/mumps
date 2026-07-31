include(CheckCCompilerFlag)
include(CheckCSourceCompiles)

# 1. Test flag acceptance (GCC/Clang syntax)
check_c_compiler_flag("-mavx512vbmi" COMPILER_SUPPORTS_AVX512VBMI)

# Prepare required flags for the compilation test
set(SAFE_CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS}")
if(COMPILER_SUPPORTS_AVX512VBMI)
    set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} -mavx512vbmi")
elseif(MSVC)
    # MSVC has no specific flag for VBMI, everything is under /arch:AVX512
    set(CMAKE_REQUIRED_FLAGS "${CMAKE_REQUIRED_FLAGS} /arch:AVX512")
endif()

# 2. Test if code using AVX-512 VBMI actually compiles
check_c_source_compiles("
    #include <immintrin.h>
    int main() {
        __m512i index = _mm512_setzero_si512();
        __m512i data = _mm512_setzero_si512();
        // _mm512_permutexvar_epi8 is specific to AVX512-VBMI
        __m512i result = _mm512_permutexvar_epi8(index, data);
        return 0;
    }
" HAVE_AVX512VBMI)

# Restore global flags
set(CMAKE_REQUIRED_FLAGS "${SAFE_CMAKE_REQUIRED_FLAGS}")

