#include <jni.h>
#include <stdlib.h>
#include <string>
#include <opencl.h>
#include <android/log.h>

#include <iostream>
#include <fstream>
#include <sstream>
#include <unistd.h>
#include <sys/time.h>
#include<time.h>
#include<stdio.h>
#include<stdlib.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <fcntl.h>
#include "ion.h"


#define TAG OpenCL
#define LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG,"OPENCL",__VA_ARGS__)
#define LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,"OPENCL",__VA_ARGS__)

const int ARRAY_SIZE = 100000;

//一、 选择OpenCL平台并创建一个上下文
cl_context CreateContext()
{
    cl_int errNum;
    cl_uint numPlatforms;
    cl_platform_id firstPlatformId;
    cl_context context = NULL;

    //选择可用的平台中的第一个
    errNum = clGetPlatformIDs(1, &firstPlatformId, &numPlatforms);
    if (errNum != CL_SUCCESS || numPlatforms <= 0)
    {
        std::cerr << "Failed to find any OpenCL platforms." << std::endl;
        return NULL;
    }

    //创建一个OpenCL上下文环境
    cl_context_properties contextProperties[] =
            {
                    CL_CONTEXT_PLATFORM,
                    (cl_context_properties)firstPlatformId,
                    0
            };
    context = clCreateContextFromType(contextProperties, CL_DEVICE_TYPE_GPU,
                                      NULL, NULL, &errNum);

    return context;
}


//二、 创建设备并创建命令队列
cl_command_queue CreateCommandQueue(cl_context context, cl_device_id *device)
{
    cl_int errNum;
    cl_device_id *devices;
    cl_command_queue commandQueue = NULL;
    size_t deviceBufferSize = -1;

    // 获取设备缓冲区大小
    errNum = clGetContextInfo(context, CL_CONTEXT_DEVICES, 0, NULL, &deviceBufferSize);

    if (deviceBufferSize <= 0)
    {
        LOGD("No devices available.");
        return NULL;
    }else{
          LOGD("deviceBufferSize 为 %d",deviceBufferSize);
    }

    // 为设备分配缓存空间
    devices = new cl_device_id[deviceBufferSize / sizeof(cl_device_id)];
    errNum = clGetContextInfo(context, CL_CONTEXT_DEVICES, deviceBufferSize, devices, NULL);
     LOGD("clGetContextInfo 结果 %d",errNum);
    //选取可用设备中的第一个
    commandQueue = clCreateCommandQueue(context, devices[0], 0, NULL);

    *device = devices[0];
    delete[] devices;
    return commandQueue;
}


// 三、创建和构建程序对象
cl_program CreateProgram(cl_context context, cl_device_id device, const char* fileName)
{
    cl_int errNum;
    cl_program program;

    std::ifstream kernelFile(fileName, std::ios::in);
    if (!kernelFile.is_open())
    {
        LOGD("Failed to open file for reading: %s\n" , fileName );
        return NULL;
    }

    std::ostringstream oss;
    oss << kernelFile.rdbuf();

    std::string srcStdStr = oss.str();
    const char *srcStr = srcStdStr.c_str();
    program = clCreateProgramWithSource(context, 1,
                                        (const char**)&srcStr,
                                        NULL, NULL);

    errNum = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);
    LOGD("构建CL内核结果 %d\n" , errNum );
    return program;
}

//创建和构建程序对象
bool CreateMemObjects(cl_context context, cl_mem memObjects[3],
                      float *a, float *b)
{
    memObjects[0] = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   sizeof(float) * ARRAY_SIZE, a, NULL);
    memObjects[1] = clCreateBuffer(context, CL_MEM_READ_ONLY | CL_MEM_COPY_HOST_PTR,
                                   sizeof(float) * ARRAY_SIZE, b, NULL);
    memObjects[2] = clCreateBuffer(context, CL_MEM_READ_WRITE,
                                   sizeof(float) * ARRAY_SIZE, NULL, NULL);
    return true;
}


// 释放OpenCL资源
void Cleanup(cl_context context, cl_command_queue commandQueue,
             cl_program program, cl_kernel kernel, cl_mem memObjects[3])
{
    for (int i = 0; i < 3; i++)
    {
        if (memObjects[i] != 0)
            clReleaseMemObject(memObjects[i]);
    }
    if (commandQueue != 0)
        clReleaseCommandQueue(commandQueue);

    if (kernel != 0)
        clReleaseKernel(kernel);

    if (program != 0)
        clReleaseProgram(program);

    if (context != 0)
        clReleaseContext(context);
}
char * getPlatformName(const cl_platform_id pid) {
    size_t param_value_size;
    clGetPlatformInfo(pid, CL_PLATFORM_NAME, 0, NULL, &param_value_size);
    char *param_value = new char[param_value_size];
    clGetPlatformInfo(pid, CL_PLATFORM_NAME, param_value_size, param_value, NULL);
    return param_value;
}
void readDeviceInfo(){
    cl_uint num_platforms;
    cl_device_id *devices;
    char name_data[48], ext_data[4096];
    cl_int i, err;
    cl_uint num_devices, addr_data;

    clGetPlatformIDs(0, NULL, &num_platforms);
    cl_platform_id *platforms = new cl_platform_id[num_platforms];
    clGetPlatformIDs(num_platforms, platforms, NULL);
    for (cl_uint i = 0; i < num_platforms; i++) {
        char *platname = getPlatformName(platforms[i]);
        LOGD(" %d Platform name is :%s",i,platname);
        size_t size;
        // vendor
        err = clGetPlatformInfo(platforms[i], CL_PLATFORM_VENDOR, 0, NULL, &size);
        char *vendor = (char *)malloc(size);
        err = clGetPlatformInfo(platforms[i], CL_PLATFORM_VENDOR, size, vendor, NULL);
        LOGD("CL_PLATFORM_VENDOR:%s\n", vendor);

        // version
        err = clGetPlatformInfo(platforms[i], CL_PLATFORM_VERSION, 0, NULL, &size);
        char *version = (char *)malloc(size);
        err = clGetPlatformInfo(platforms[i], CL_PLATFORM_VERSION, size, version, NULL);
        LOGD("CL_PLATFORM_VERSION:%s\n", version);

        // profile
        err = clGetPlatformInfo(platforms[i], CL_PLATFORM_PROFILE, 0, NULL, &size);
        char *profile = (char *)malloc(size);
        err = clGetPlatformInfo(platforms[i], CL_PLATFORM_PROFILE, size, profile, NULL);
        LOGD("CL_PLATFORM_PROFILE:%s\n", profile);

        err = clGetDeviceIDs(platforms[i], CL_DEVICE_TYPE_ALL, 0, NULL, &num_devices);
        if (err < 0) {
            LOGD("Couldn't find any devices");
            exit(1);
        } else{
            LOGD(" find  devices num %d",num_devices);
        }

        /* Access connected devices */
        devices = (cl_device_id*)
                malloc(sizeof(cl_device_id) * num_devices);
        clGetDeviceIDs(platforms[i], CL_DEVICE_TYPE_ALL,
                       num_devices, devices, NULL);

        /*循环显示platform的所有device（CPU和显卡）信息。*/
        for (i = 0; i < (int)num_devices; i++) {

            err = clGetDeviceInfo(devices[i], CL_DEVICE_NAME,
                                  sizeof(name_data), name_data, NULL);
            if (err < 0) {
                LOGD("Couldn't read extension data");
                exit(1);
            }

            clGetDeviceInfo(devices[i], CL_DEVICE_ADDRESS_BITS,
                            sizeof(ext_data), &addr_data, NULL);

            clGetDeviceInfo(devices[i], CL_DEVICE_EXTENSIONS,
                            sizeof(ext_data), ext_data, NULL);
            LOGD("NAME: %s\nADDRESS_WIDTH: %u\nEXTENSIONS: %s\n\n",
                 name_data, addr_data, ext_data);
        }

        free(vendor);
        free(version);
        free(profile);

    }
    //end
}
int test()
{



    cl_context context = 0;
    cl_command_queue commandQueue = 0;
    cl_program program = 0;
    cl_device_id device = 0;
    cl_kernel kernel = 0;
    cl_mem memObjects[3] = { 0, 0, 0 };
    cl_int errNum;
    // uint64_t t1,t2,t3;
    clock_t t1,t2,t3;


    //const char* filename = "/sdcard/neoscrypt-xaya.cl";
    const char* filename = "/sdcard/FunTest.cl";
    // 一、选择OpenCL平台并创建一个上下文
    context = CreateContext();

    // 二、 创建设备并创建命令队列
    commandQueue = CreateCommandQueue(context, &device);

    //创建和构建程序对象
    program = CreateProgram(context, device, filename);//"HelloWorld.cl");

    // 四、 创建OpenCL内核并分配内存空间
    kernel = clCreateKernel(program, "HelloWorld", NULL);

    //创建要处理的数据
    float result[ARRAY_SIZE];
    float a[ARRAY_SIZE];
    float b[ARRAY_SIZE];
    for (int i = 0; i < ARRAY_SIZE; i++)
    {
        a[i] = (float)i;
        b[i] = (float)(ARRAY_SIZE - i);
    }

    t1 = clock();  //mach_absolute_time();
    LOGD("t1 = %.8f\n",(double)t1);
    for(int j = 0;j <  ARRAY_SIZE;j++){
        result[j] = a[j]+b[j];

    }

    t2 = clock(); //mach_absolute_time();
    LOGD("t2 = %.8f\n",(double)t2);

    //创建内存对象
    if (!CreateMemObjects(context, memObjects, a, b))
    {
        Cleanup(context, commandQueue, program, kernel, memObjects);
        return 1;
    }

    // 五、 设置内核数据并执行内核
    errNum = clSetKernelArg(kernel, 0, sizeof(cl_mem), &memObjects[0]);
    errNum |= clSetKernelArg(kernel, 1, sizeof(cl_mem), &memObjects[1]);
    errNum |= clSetKernelArg(kernel, 2, sizeof(cl_mem), &memObjects[2]);

    size_t globalWorkSize[1] = { ARRAY_SIZE };
    size_t localWorkSize[1] = { 1 };

    errNum = clEnqueueNDRangeKernel(commandQueue, kernel, 1, NULL,
                                    globalWorkSize, localWorkSize,
                                    0, NULL, NULL);

    // 六、 读取执行结果并释放OpenCL资源
    errNum = clEnqueueReadBuffer(commandQueue, memObjects[2], CL_TRUE,
                                 0, ARRAY_SIZE * sizeof(float), result,
                                 0, NULL, NULL);

    t3 = clock();  //mach_absolute_time();




    LOGD("cpu t = %.8f\n",(float)(t2-t1)/CLOCKS_PER_SEC);
    LOGD("gpu t = %.8f \n",(double)(t3-t2)/CLOCKS_PER_SEC);


    LOGD("Executed program succesfully.");
    getchar();
    Cleanup(context, commandQueue, program, kernel, memObjects);

    return 0;
}


extern "C"
JNIEXPORT jstring JNICALL
Java_com_example_wangmingyong_opencl_MainActivity_stringFromJNI(
        JNIEnv *env,
        jobject /* this */) {

    readDeviceInfo();
    test();

    std::string hello = "Hello from C++";
    return env->NewStringUTF(hello.c_str());
}
