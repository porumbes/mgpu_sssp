#pragma GCC diagnostic ignored "-Wunused-result"

#include "sssp_cpu.hxx"
#include "sssp_1gpu.hxx"
#include "sssp_mgpu.hxx"

#include <cuda.h>               /* for Gpuinfo */
#include <cuda_runtime_api.h>   /* for Gpuinfo */
#include <iomanip>
#include <cstdlib>
#include <fstream>
#include "json.hpp"
using json = nlohmann::json;

//#define RUN_CPU

// --
// Global defs

typedef int Int;
typedef float Real;

// graph
Int n_nodes;
Int n_edges;
Int* indptr;
Int* rindices;
Int* cindices;
Real* data;

void load_data(std::string inpath) {
    FILE *ptr;
    ptr = fopen(inpath.c_str(), "rb");

    fread(&n_nodes,   sizeof(Int), 1, ptr);
    fread(&n_nodes,   sizeof(Int), 1, ptr);
    fread(&n_edges,   sizeof(Int), 1, ptr);

    indptr   = (Int*)  malloc(sizeof(Int)  * (n_nodes + 1)  );
    cindices = (Int*)  malloc(sizeof(Int)  * n_edges         );
    rindices = (Int*)  malloc(sizeof(Int)  * n_edges         );
    data     = (Real*) malloc(sizeof(Real) * n_edges         );

    fread(indptr,  sizeof(Int),   n_nodes + 1 , ptr);  // send directy to the memory since thats what the thing is.
    fread(cindices, sizeof(Int),  n_edges      , ptr);
    fread(data,    sizeof(Real),  n_edges      , ptr);
    
    for(Int src = 0; src < n_nodes; src++) {
        for(Int offset = indptr[src]; offset < indptr[src + 1]; offset++) {
            rindices[offset] = src;
        }
    }
}

json gpu_info_json() {
    json j;
    cudaDeviceProp devProps;

    int deviceCount;
    cudaGetDeviceCount(&deviceCount);
    if (deviceCount == 0)   /* no valid devices */
    {
        return j;        /* empty */
    }
    int dev = 0;
    cudaGetDevice(&dev);
    cudaGetDeviceProperties(&devProps, dev);
    j["gpuinfo"]["name"] = devProps.name;
    j["gpuinfo"]["total_global_mem"] = int64_t(devProps.totalGlobalMem);
    j["gpuinfo"]["major"] = devProps.major;
    j["gpuinfo"]["minor"] = devProps.minor;
    j["gpuinfo"]["clock_rate"] = devProps.clockRate;
    j["gpuinfo"]["multi_processor_count"] = devProps.multiProcessorCount;

    int runtimeVersion, driverVersion;
    cudaRuntimeGetVersion(&runtimeVersion);
    cudaDriverGetVersion(&driverVersion);
    j["gpuinfo"]["driver_api"] = CUDA_VERSION;
    j["gpuinfo"]["driver_version"] = driverVersion;
    j["gpuinfo"]["runtime_version"] = runtimeVersion;
    j["gpuinfo"]["compute_version"] = devProps.major * 10 + devProps.minor;

    return j;    
}

int main(int n_args, char** argument_array) {
    int n_gpus = 1;
    cudaGetDeviceCount(&n_gpus);
    
    // ---------------- INPUT ----------------
    // main path_to_dataset.bin num_seeds path_to_output.json
    if(n_args < 1 || n_args != 4) {
        std::cout << "Usage: main <input_dataset.bin> <num_seeds> <path_to_output.json>\n";
	std::exit(EXIT_FAILURE);
    }

    load_data(argument_array[1]);
    int n_seeds = 1;
    n_seeds = (int)atoi(argument_array[2]);

    Int* seeds = (Int*)malloc(n_seeds * sizeof(Int));
    for(Int seed = 0; seed < n_seeds; seed++) {
        seeds[seed] = seed;
    }
    
    // ---------------- CPU ----------------
    
    Real* cpu_dist = (Real*)malloc(n_nodes * sizeof(Real));
    long long cpu_time = 0;
#ifdef RUN_CPU
    cpu_time = sssp_cpu(cpu_dist, n_seeds, seeds, n_nodes, n_edges, indptr, cindices, data);
#endif
    
    // ---------------- GPU ----------------
    
    Real* gpu_dist = (Real*)malloc(n_nodes * sizeof(Real));
    long long gpu_time = 0;
    if(n_gpus == 1) {
        gpu_time = sssp_1gpu(gpu_dist, n_seeds, seeds, n_nodes, n_edges, rindices, cindices, data);
    } else {
        gpu_time = sssp_mgpu(gpu_dist, n_seeds, seeds, n_nodes, n_edges, rindices, cindices, data, n_gpus);
    }

    for(Int i = 0; i < min(n_nodes, 40); i++) std::cout << cpu_dist[i] << " ";
    std::cout << std::endl;
    for(Int i = 0; i < min(n_nodes, 40); i++) std::cout << gpu_dist[i] << " ";
    std::cout << std::endl;

    // ---------------- VALIDATE ----------------
    
    int n_errors = 0;
#ifdef RUN_CPU
    for(Int i = 0; i < n_nodes; i++) {
        if(cpu_dist[i] != gpu_dist[i]) n_errors++;
    }
#endif
    
    std::cout << "n_seeds=" << n_seeds 
	    << " | cpu_time=" << cpu_time 
	    << " | gpu_time_microseconds=" << gpu_time 
	    << " | n_errors=" << n_errors 
	    << " | n_gpus=" << n_gpus << std::endl;
    std::cout << "dataset=" << argument_array[1] << '\n'
	      << "num-vertices=" << n_nodes << '\n'
	      << "num-edges=" << n_edges << '\n';
    
    auto j = gpu_info_json();
    j["primitive"] = "vn";
    j["graph-file"] = std::string(argument_array[1]);
    j["num_gpus"] = n_gpus;
    j["graph-edges"] = n_edges;
    j["graph-nodes"] = n_nodes;
    j["gpu-elapsed-ms"] = (double)gpu_time / 1000.0;
    time_t now = time(NULL);
    j["time"] = ctime(&now);
    j["variant"] = std::string("num_seeds:") + std::to_string(n_seeds);

    // get the dataset from the json
    auto dataset = std::string(argument_array[3]);
    std::size_t p1 = dataset.find("vn__") + 4; // skip the expected "vn__"
    std::size_t p2 = dataset.find("__GPU");
    j["dataset"] = dataset.substr(p1, p2-p1);

    //std::cout << '\n' << std::setw(4) << j << '\n';
    std::ofstream output_json(argument_array[3]);
    output_json << std::setw(4) << j << std::endl;

    return 0;
}
