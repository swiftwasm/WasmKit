#ifndef wasmcomponentld_H
#define wasmcomponentld_H

#ifdef __cplusplus
extern "C" {
#endif

#include "w2c2_base.h"

typedef struct wasmcomponentldInstance {
wasmModuleInstance common;
wasmMemory* m0;
wasmTable t0;
U32 g0;
U32 g1;
} wasmcomponentldInstance;

U32 wasi_snapshot_preview1__random_get(void*,U32,U32);

U32 wasi_snapshot_preview1__args_get(void*,U32,U32);

U32 wasi_snapshot_preview1__args_sizes_get(void*,U32,U32);

U32 wasi_snapshot_preview1__clock_time_get(void*,U32,U64,U32);

U32 wasi_snapshot_preview1__fd_filestat_get(void*,U32,U32);

U32 wasi_snapshot_preview1__fd_read(void*,U32,U32,U32,U32);

U32 wasi_snapshot_preview1__fd_readdir(void*,U32,U32,U32,U64,U32);

U32 wasi_snapshot_preview1__fd_write(void*,U32,U32,U32,U32);

U32 wasi_snapshot_preview1__path_create_directory(void*,U32,U32,U32);

U32 wasi_snapshot_preview1__path_filestat_get(void*,U32,U32,U32,U32,U32);

U32 wasi_snapshot_preview1__path_open(void*,U32,U32,U32,U32,U32,U64,U64,U32,U32);

U32 wasi_snapshot_preview1__path_remove_directory(void*,U32,U32,U32);

U32 wasi_snapshot_preview1__path_unlink_file(void*,U32,U32,U32);

U32 wasi_snapshot_preview1__environ_get(void*,U32,U32);

U32 wasi_snapshot_preview1__environ_sizes_get(void*,U32,U32);

U32 wasi_snapshot_preview1__fd_close(void*,U32);

U32 wasi_snapshot_preview1__fd_fdstat_get(void*,U32,U32);

U32 wasi_snapshot_preview1__fd_prestat_get(void*,U32,U32);

U32 wasi_snapshot_preview1__fd_prestat_dir_name(void*,U32,U32,U32);

void wasi_snapshot_preview1__proc_exit(void*,U32);

void f20(wasmcomponentldInstance*);

void f21(wasmcomponentldInstance*);

U32 f22(wasmcomponentldInstance*,U32);

void f23(wasmcomponentldInstance*,U32);

U32 f24(wasmcomponentldInstance*,U32);

void f25(wasmcomponentldInstance*);

U32 f26(wasmcomponentldInstance*);

U32 f27(wasmcomponentldInstance*,U32,U32);

void f28(wasmcomponentldInstance*,U32,U32,U32);

U32 f29(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f30(wasmcomponentldInstance*,U32,U32);

void f31(wasmcomponentldInstance*,U32,U32);

void f32(wasmcomponentldInstance*);

void f33(wasmcomponentldInstance*,U32,U32);

void f34(wasmcomponentldInstance*,U32);

void f35(wasmcomponentldInstance*,U32);

void f36(wasmcomponentldInstance*,U32);

void f37(wasmcomponentldInstance*,U32);

void f38(wasmcomponentldInstance*,U32);

void f39(wasmcomponentldInstance*,U32);

void f40(wasmcomponentldInstance*,U32);

void f41(wasmcomponentldInstance*,U32);

void f42(wasmcomponentldInstance*,U32);

void f43(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f44(wasmcomponentldInstance*,U32,U32);

U32 f45(wasmcomponentldInstance*,U32,U32);

U32 f46(wasmcomponentldInstance*,U32,U32,U32);

void f47(wasmcomponentldInstance*,U32,U32);

U32 f48(wasmcomponentldInstance*,U32,U32);

U32 f49(wasmcomponentldInstance*,U32);

void f50(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f51(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f52(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f53(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f54(wasmcomponentldInstance*,U32,U32);

void f55(wasmcomponentldInstance*,U32,U32);

void f56(wasmcomponentldInstance*,U32,U32);

void f57(wasmcomponentldInstance*,U32,U32);

void f58(wasmcomponentldInstance*,U32,U32);

void f59(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f60(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f61(wasmcomponentldInstance*,U32,U32);

void f62(wasmcomponentldInstance*,U32,U32);

void f63(wasmcomponentldInstance*,U32,U32,U32);

void f64(wasmcomponentldInstance*);

void f65(wasmcomponentldInstance*,U32,U32);

void f66(wasmcomponentldInstance*,U32,U32);

U32 f67(wasmcomponentldInstance*,U32,U32,U32);

void f68(wasmcomponentldInstance*,U32);

void f69(wasmcomponentldInstance*,U32,U32);

void f70(wasmcomponentldInstance*,U32,U32,U32);

void f71(wasmcomponentldInstance*,U32,U32,U32);

void f72(wasmcomponentldInstance*,U32,U32,U32);

void f73(wasmcomponentldInstance*,U32,U32,U32);

U32 f74(wasmcomponentldInstance*,U32,U32);

U32 f75(wasmcomponentldInstance*,U32,U32);

U32 f76(wasmcomponentldInstance*,U32,U32);

void f77(wasmcomponentldInstance*,U32);

void f78(wasmcomponentldInstance*,U32);

U32 f79(wasmcomponentldInstance*,U32,U32);

void f80(wasmcomponentldInstance*,U32,U32,U32);

void f81(wasmcomponentldInstance*,U32,U32,U32);

void f82(wasmcomponentldInstance*,U32);

void f83(wasmcomponentldInstance*,U32);

void f84(wasmcomponentldInstance*,U32);

void f85(wasmcomponentldInstance*,U32);

void f86(wasmcomponentldInstance*,U32);

void f87(wasmcomponentldInstance*,U32);

void f88(wasmcomponentldInstance*,U32);

void f89(wasmcomponentldInstance*,U32);

void f90(wasmcomponentldInstance*,U32);

void f91(wasmcomponentldInstance*,U32);

void f92(wasmcomponentldInstance*,U32);

void f93(wasmcomponentldInstance*,U32);

void f94(wasmcomponentldInstance*,U32);

void f95(wasmcomponentldInstance*,U32,U32,U32);

void f96(wasmcomponentldInstance*,U32,U32);

void f97(wasmcomponentldInstance*,U32,U32);

void f98(wasmcomponentldInstance*,U32,U32);

void f99(wasmcomponentldInstance*,U32,U32);

void f100(wasmcomponentldInstance*,U32);

void f101(wasmcomponentldInstance*,U32,U32);

U32 f102(wasmcomponentldInstance*,U32,U32);

U32 f103(wasmcomponentldInstance*,U32,U32);

U32 f104(wasmcomponentldInstance*,U32,U32);

U32 f105(wasmcomponentldInstance*,U32,U32);

U32 f106(wasmcomponentldInstance*,U32,U32);

U32 f107(wasmcomponentldInstance*,U32,U32);

U32 f108(wasmcomponentldInstance*,U32,U32);

U32 f109(wasmcomponentldInstance*,U32,U32);

U32 f110(wasmcomponentldInstance*,U32,U32);

U32 f111(wasmcomponentldInstance*,U32,U32);

void f112(wasmcomponentldInstance*,U32);

void f113(wasmcomponentldInstance*,U32);

void f114(wasmcomponentldInstance*,U32);

void f115(wasmcomponentldInstance*,U32);

U32 f116(wasmcomponentldInstance*,U32,U32);

U32 f117(wasmcomponentldInstance*,U32,U32);

U32 f118(wasmcomponentldInstance*,U32,U32);

U32 f119(wasmcomponentldInstance*,U32,U32);

U32 f120(wasmcomponentldInstance*,U32,U32,U32);

U32 f121(wasmcomponentldInstance*,U32,U32);

U32 f122(wasmcomponentldInstance*,U32,U32);

void f123(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f124(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f125(wasmcomponentldInstance*,U32,U32);

void f126(wasmcomponentldInstance*,U32,U32);

void f127(wasmcomponentldInstance*,U32,U32);

void f128(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f129(wasmcomponentldInstance*,U32,U32);

void f130(wasmcomponentldInstance*,U32,U32,U32);

void f131(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f132(wasmcomponentldInstance*,U32,U32);

U32 f133(wasmcomponentldInstance*,U32,U32);

U32 f134(wasmcomponentldInstance*,U32,U32);

U32 f135(wasmcomponentldInstance*,U32,U32);

U32 f136(wasmcomponentldInstance*,U32,U32);

U32 f137(wasmcomponentldInstance*,U32,U32);

U32 f138(wasmcomponentldInstance*,U32,U32);

U32 f139(wasmcomponentldInstance*,U32,U32);

U32 f140(wasmcomponentldInstance*,U32,U32);

void f141(wasmcomponentldInstance*,U32);

U32 f142(wasmcomponentldInstance*,U32,U32);

void f143(wasmcomponentldInstance*,U32);

void f144(wasmcomponentldInstance*,U32);

void f145(wasmcomponentldInstance*,U32);

void f146(wasmcomponentldInstance*,U32,U32,U32,U32);

void f147(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f148(wasmcomponentldInstance*,U32,U32);

U32 f149(wasmcomponentldInstance*,U32,U32);

U32 f150(wasmcomponentldInstance*,U32,U32);

U32 f151(wasmcomponentldInstance*,U32,U32);

void f152(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32);

void f153(wasmcomponentldInstance*,U32,U32,U32);

U32 f154(wasmcomponentldInstance*,U32);

U32 f155(wasmcomponentldInstance*,U32,U32);

U32 f156(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f157(wasmcomponentldInstance*,U32,U32,U32);

void f158(wasmcomponentldInstance*,U32);

void f159(wasmcomponentldInstance*,U32,U32);

void f160(wasmcomponentldInstance*,U32,U32);

U32 f161(wasmcomponentldInstance*,U32,U32);

U32 f162(wasmcomponentldInstance*,U32,U32);

U32 f163(wasmcomponentldInstance*,U32,U32);

U32 f164(wasmcomponentldInstance*,U32,U32);

U32 f165(wasmcomponentldInstance*,U32,U32);

U32 f166(wasmcomponentldInstance*,U32,U32);

void f167(wasmcomponentldInstance*,U32);

void f168(wasmcomponentldInstance*,U32);

void f169(wasmcomponentldInstance*,U32);

void f170(wasmcomponentldInstance*,U32);

void f171(wasmcomponentldInstance*,U32);

void f172(wasmcomponentldInstance*,U32);

void f173(wasmcomponentldInstance*,U32,U32);

void f174(wasmcomponentldInstance*,U32,U32);

void f175(wasmcomponentldInstance*,U32,U32,U32);

void f176(wasmcomponentldInstance*,U32,U32);

void f177(wasmcomponentldInstance*,U32,U32);

U32 f178(wasmcomponentldInstance*,U32,U32);

U32 f179(wasmcomponentldInstance*,U32,U32);

U32 f180(wasmcomponentldInstance*,U32,U32);

U32 f181(wasmcomponentldInstance*,U32,U32);

U32 f182(wasmcomponentldInstance*,U32,U32);

U32 f183(wasmcomponentldInstance*,U32,U32);

U32 f184(wasmcomponentldInstance*,U32,U32);

U32 f185(wasmcomponentldInstance*,U32,U32);

U32 f186(wasmcomponentldInstance*,U32,U32);

U32 f187(wasmcomponentldInstance*,U32,U32);

U32 f188(wasmcomponentldInstance*,U32,U32);

U32 f189(wasmcomponentldInstance*,U32,U32);

void f190(wasmcomponentldInstance*,U32,U32);

U32 f191(wasmcomponentldInstance*,U32,U32);

void f192(wasmcomponentldInstance*,U32);

void f193(wasmcomponentldInstance*,U32);

void f194(wasmcomponentldInstance*,U32);

void f195(wasmcomponentldInstance*,U32,U32);

void f196(wasmcomponentldInstance*,U32,U32,U32);

U32 f197(wasmcomponentldInstance*,U32,U32);

U32 f198(wasmcomponentldInstance*,U32,U32);

U32 f199(wasmcomponentldInstance*,U32,U32);

void f200(wasmcomponentldInstance*,U32,U32,U32);

U32 f201(wasmcomponentldInstance*,U32,U32);

void f202(wasmcomponentldInstance*,U32,U32);

void f203(wasmcomponentldInstance*,U32);

void f204(wasmcomponentldInstance*,U32);

void f205(wasmcomponentldInstance*,U32);

void f206(wasmcomponentldInstance*,U32);

void f207(wasmcomponentldInstance*,U32);

void f208(wasmcomponentldInstance*,U32);

void f209(wasmcomponentldInstance*,U32);

void f210(wasmcomponentldInstance*,U32);

void f211(wasmcomponentldInstance*,U32);

void f212(wasmcomponentldInstance*,U32,U32);

void f213(wasmcomponentldInstance*,U32,U32);

void f214(wasmcomponentldInstance*,U32,U32);

void f215(wasmcomponentldInstance*,U32,U32);

void f216(wasmcomponentldInstance*,U32,U32);

void f217(wasmcomponentldInstance*,U32,U32);

void f218(wasmcomponentldInstance*,U32,U32,U32);

void f219(wasmcomponentldInstance*,U32,U32);

void f220(wasmcomponentldInstance*,U32,U32);

void f221(wasmcomponentldInstance*,U32,U32);

void f222(wasmcomponentldInstance*,U32,U32);

void f223(wasmcomponentldInstance*,U32,U32);

void f224(wasmcomponentldInstance*,U32,U32);

void f225(wasmcomponentldInstance*,U32,U32);

void f226(wasmcomponentldInstance*,U32,U32);

void f227(wasmcomponentldInstance*,U32,U32);

void f228(wasmcomponentldInstance*,U32,U32);

void f229(wasmcomponentldInstance*,U32,U32);

void f230(wasmcomponentldInstance*,U32,U32);

void f231(wasmcomponentldInstance*,U32,U32);

void f232(wasmcomponentldInstance*,U32);

void f233(wasmcomponentldInstance*,U32);

void f234(wasmcomponentldInstance*,U32);

void f235(wasmcomponentldInstance*,U32);

void f236(wasmcomponentldInstance*,U32);

void f237(wasmcomponentldInstance*,U32);

void f238(wasmcomponentldInstance*,U32);

void f239(wasmcomponentldInstance*,U32);

void f240(wasmcomponentldInstance*,U32);

U32 f241(wasmcomponentldInstance*,U32,U64,U64);

U32 f242(wasmcomponentldInstance*,U32,U64,U64);

U32 f243(wasmcomponentldInstance*,U32,U64,U64);

U32 f244(wasmcomponentldInstance*,U32,U64,U64);

U32 f245(wasmcomponentldInstance*,U32,U64,U64);

U32 f246(wasmcomponentldInstance*,U32,U64,U64);

U32 f247(wasmcomponentldInstance*,U32,U64,U64);

U32 f248(wasmcomponentldInstance*,U32);

U32 f249(wasmcomponentldInstance*,U32);

void f250(wasmcomponentldInstance*,U32,U64,U64);

void f251(wasmcomponentldInstance*,U32,U64,U64);

void f252(wasmcomponentldInstance*,U32,U64,U64);

void f253(wasmcomponentldInstance*,U32,U64,U64);

void f254(wasmcomponentldInstance*,U32,U64,U64);

U32 f255(wasmcomponentldInstance*,U32,U64,U64);

U32 f256(wasmcomponentldInstance*,U32,U64,U64);

void f257(wasmcomponentldInstance*,U32,U64,U64);

void f258(wasmcomponentldInstance*,U32,U64,U64);

void f259(wasmcomponentldInstance*,U32,U32);

void f260(wasmcomponentldInstance*,U32,U32);

void f261(wasmcomponentldInstance*,U32,U32);

void f262(wasmcomponentldInstance*,U32,U32);

void f263(wasmcomponentldInstance*,U32,U32);

void f264(wasmcomponentldInstance*,U32,U32);

void f265(wasmcomponentldInstance*,U32,U32);

void f266(wasmcomponentldInstance*,U32,U32);

void f267(wasmcomponentldInstance*,U32,U32);

void f268(wasmcomponentldInstance*,U32,U32);

void f269(wasmcomponentldInstance*,U32,U32);

U32 f270(wasmcomponentldInstance*,U32,U32);

U32 f271(wasmcomponentldInstance*,U32,U32);

U32 f272(wasmcomponentldInstance*,U32,U32);

U32 f273(wasmcomponentldInstance*,U32,U32);

U32 f274(wasmcomponentldInstance*,U32,U32);

U32 f275(wasmcomponentldInstance*,U32,U32);

U32 f276(wasmcomponentldInstance*,U32,U32);

void f277(wasmcomponentldInstance*,U32,U32);

U32 f278(wasmcomponentldInstance*,U32,U32);

void f279(wasmcomponentldInstance*,U32,U32);

U32 f280(wasmcomponentldInstance*,U32,U32);

U32 f281(wasmcomponentldInstance*,U32,U32);

U32 f282(wasmcomponentldInstance*,U32,U32);

U32 f283(wasmcomponentldInstance*,U32,U32);

U32 f284(wasmcomponentldInstance*,U32,U32);

U32 f285(wasmcomponentldInstance*,U32,U32);

void f286(wasmcomponentldInstance*,U32,U32);

U32 f287(wasmcomponentldInstance*,U32,U32);

void f288(wasmcomponentldInstance*,U32);

void f289(wasmcomponentldInstance*,U32);

void f290(wasmcomponentldInstance*,U32);

void f291(wasmcomponentldInstance*,U32);

void f292(wasmcomponentldInstance*,U32);

void f293(wasmcomponentldInstance*,U32);

void f294(wasmcomponentldInstance*,U32);

void f295(wasmcomponentldInstance*,U32);

void f296(wasmcomponentldInstance*,U32);

void f297(wasmcomponentldInstance*,U32);

void f298(wasmcomponentldInstance*,U32);

void f299(wasmcomponentldInstance*,U32);

void f300(wasmcomponentldInstance*,U32);

void f301(wasmcomponentldInstance*,U32);

void f302(wasmcomponentldInstance*,U32);

void f303(wasmcomponentldInstance*,U32);

void f304(wasmcomponentldInstance*,U32);

void f305(wasmcomponentldInstance*,U32,U32);

void f306(wasmcomponentldInstance*,U32,U32);

void f307(wasmcomponentldInstance*,U32,U32);

void f308(wasmcomponentldInstance*,U32,U32,U32);

void f309(wasmcomponentldInstance*,U32,U32,U32);

void f310(wasmcomponentldInstance*,U32,U32);

void f311(wasmcomponentldInstance*,U32,U32);

void f312(wasmcomponentldInstance*,U32,U32);

U32 f313(wasmcomponentldInstance*,U32,U32);

U32 f314(wasmcomponentldInstance*,U32,U32);

U32 f315(wasmcomponentldInstance*,U32,U32);

void f316(wasmcomponentldInstance*,U32,U32);

void f317(wasmcomponentldInstance*,U32,U32);

void f318(wasmcomponentldInstance*,U32,U32);

void f319(wasmcomponentldInstance*,U32,U32);

void f320(wasmcomponentldInstance*,U32,U32);

void f321(wasmcomponentldInstance*,U32,U32);

void f322(wasmcomponentldInstance*,U32,U32);

void f323(wasmcomponentldInstance*,U32,U32);

void f324(wasmcomponentldInstance*,U32,U32);

U32 f325(wasmcomponentldInstance*,U32);

void f326(wasmcomponentldInstance*,U32,U32);

void f327(wasmcomponentldInstance*,U32,U32);

void f328(wasmcomponentldInstance*,U32,U32);

void f329(wasmcomponentldInstance*,U32,U32);

void f330(wasmcomponentldInstance*,U32,U32);

void f331(wasmcomponentldInstance*,U32,U32);

void f332(wasmcomponentldInstance*,U32,U32);

void f333(wasmcomponentldInstance*,U32,U32);

void f334(wasmcomponentldInstance*,U32,U32);

U32 f335(wasmcomponentldInstance*,U32,U32);

U32 f336(wasmcomponentldInstance*,U32);

U32 f337(wasmcomponentldInstance*,U32,U32);

U32 f338(wasmcomponentldInstance*,U32,U32);

U32 f339(wasmcomponentldInstance*,U32,U32,U32);

U32 f340(wasmcomponentldInstance*,U32,U32);

U32 f341(wasmcomponentldInstance*,U64,U32);

U32 f342(wasmcomponentldInstance*,U32,U32);

U32 f343(wasmcomponentldInstance*,U32,U32);

U32 f344(wasmcomponentldInstance*,U32);

U32 f345(wasmcomponentldInstance*,U32);

U32 f346(wasmcomponentldInstance*,U32);

U32 f347(wasmcomponentldInstance*,U32);

void f348(wasmcomponentldInstance*,U32,U32);

void f349(wasmcomponentldInstance*,U32,U32);

U32 f350(wasmcomponentldInstance*,U32,U32);

U32 f351(wasmcomponentldInstance*,U32,U32);

U32 f352(wasmcomponentldInstance*,U32,U32);

U32 f353(wasmcomponentldInstance*,U32,U32);

void f354(wasmcomponentldInstance*,U32,U32);

void f355(wasmcomponentldInstance*,U32,U32);

void f356(wasmcomponentldInstance*,U32,U32,U32,U32);

void f357(wasmcomponentldInstance*,U32,U32,U32,U32);

void f358(wasmcomponentldInstance*,U32,U32,U32,U32);

void f359(wasmcomponentldInstance*,U32,U32,U32,U32);

void f360(wasmcomponentldInstance*,U32,U32,U32,U32);

void f361(wasmcomponentldInstance*,U32,U32,U32,U32);

void f362(wasmcomponentldInstance*,U32,U32);

void f363(wasmcomponentldInstance*,U32,U32,U32,U32);

void f364(wasmcomponentldInstance*,U32,U32);

void f365(wasmcomponentldInstance*,U32,U32,U32,U32);

void f366(wasmcomponentldInstance*,U32,U32);

void f367(wasmcomponentldInstance*,U32);

U32 f368(wasmcomponentldInstance*,U32,U32);

U32 f369(wasmcomponentldInstance*,U32,U32);

U32 f370(wasmcomponentldInstance*,U32,U32);

U32 f371(wasmcomponentldInstance*,U32,U32);

void f372(wasmcomponentldInstance*,U32,U32);

void f373(wasmcomponentldInstance*,U32,U32);

void f374(wasmcomponentldInstance*,U32);

void f375(wasmcomponentldInstance*,U32);

void f376(wasmcomponentldInstance*,U32);

U32 f377(wasmcomponentldInstance*,U32,U32);

U32 f378(wasmcomponentldInstance*,U32,U32,U32);

void f379(wasmcomponentldInstance*,U32,U32,U32);

void f380(wasmcomponentldInstance*,U32,U32,U32);

void f381(wasmcomponentldInstance*,U32);

void f382(wasmcomponentldInstance*,U32,U32,U32);

U32 f383(wasmcomponentldInstance*,U32,U32);

U32 f384(wasmcomponentldInstance*,U32,U32);

U32 f385(wasmcomponentldInstance*,U32,U32);

void f386(wasmcomponentldInstance*,U32,U32,U32,U32);

void f387(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f388(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f389(wasmcomponentldInstance*,U32,U32,U32,U32);

void f390(wasmcomponentldInstance*,U32,U32,U32);

U32 f391(wasmcomponentldInstance*,U32,U32);

void f392(wasmcomponentldInstance*,U32);

void f393(wasmcomponentldInstance*,U32,U32);

void f394(wasmcomponentldInstance*,U32,U32,U32);

void f395(wasmcomponentldInstance*,U32);

void f396(wasmcomponentldInstance*,U32);

void f397(wasmcomponentldInstance*,U32,U32,U32,U32);

void f398(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f399(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32);

void f400(wasmcomponentldInstance*,U32);

void f401(wasmcomponentldInstance*,U32);

void f402(wasmcomponentldInstance*,U32,U32);

void f403(wasmcomponentldInstance*,U32,U32);

void f404(wasmcomponentldInstance*,U32,U32,U32);

void f405(wasmcomponentldInstance*,U32,U32);

U32 f406(wasmcomponentldInstance*,U32,U32);

void f407(wasmcomponentldInstance*,U32,U32,U32,U32);

void f408(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f409(wasmcomponentldInstance*,U32,U32);

void f410(wasmcomponentldInstance*,U32,U32);

U32 f411(wasmcomponentldInstance*,U32,U32);

void f412(wasmcomponentldInstance*,U32,U32,U32);

void f413(wasmcomponentldInstance*,U32,U32,U32);

void f414(wasmcomponentldInstance*,U32,U32);

U32 f415(wasmcomponentldInstance*,U32);

void f416(wasmcomponentldInstance*,U32,U32,U32);

void f417(wasmcomponentldInstance*,U32);

U32 f418(wasmcomponentldInstance*,U32,U32);

U32 f419(wasmcomponentldInstance*,U32,U32);

void f420(wasmcomponentldInstance*,U32);

void f421(wasmcomponentldInstance*,U32);

void f422(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f423(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f424(wasmcomponentldInstance*,U32,U32,U32,U32);

void f425(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f426(wasmcomponentldInstance*,U32,U32);

void f427(wasmcomponentldInstance*,U32);

void f428(wasmcomponentldInstance*,U32);

void f429(wasmcomponentldInstance*,U32);

void f430(wasmcomponentldInstance*,U32);

void f431(wasmcomponentldInstance*,U32);

void f432(wasmcomponentldInstance*,U32);

void f433(wasmcomponentldInstance*,U32);

void f434(wasmcomponentldInstance*,U32);

void f435(wasmcomponentldInstance*,U32);

void f436(wasmcomponentldInstance*,U32);

void f437(wasmcomponentldInstance*,U32);

void f438(wasmcomponentldInstance*,U32);

void f439(wasmcomponentldInstance*,U32);

void f440(wasmcomponentldInstance*,U32);

void f441(wasmcomponentldInstance*,U32);

void f442(wasmcomponentldInstance*,U32);

U32 f443(wasmcomponentldInstance*,U32,U32);

void f444(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f445(wasmcomponentldInstance*,U32,U32,U32);

void f446(wasmcomponentldInstance*,U32,U32,U32,U32);

void f447(wasmcomponentldInstance*,U32,U32,U32,U32);

void f448(wasmcomponentldInstance*,U32);

void f449(wasmcomponentldInstance*,U32);

void f450(wasmcomponentldInstance*,U32);

void f451(wasmcomponentldInstance*,U32);

void f452(wasmcomponentldInstance*,U32);

void f453(wasmcomponentldInstance*,U32);

void f454(wasmcomponentldInstance*,U32);

void f455(wasmcomponentldInstance*,U32);

void f456(wasmcomponentldInstance*,U32);

void f457(wasmcomponentldInstance*,U32);

void f458(wasmcomponentldInstance*,U32);

void f459(wasmcomponentldInstance*,U32);

void f460(wasmcomponentldInstance*,U32);

void f461(wasmcomponentldInstance*,U32);

void f462(wasmcomponentldInstance*,U32);

void f463(wasmcomponentldInstance*,U32);

void f464(wasmcomponentldInstance*,U32);

void f465(wasmcomponentldInstance*,U32);

U32 f466(wasmcomponentldInstance*,U32,U32);

U32 f467(wasmcomponentldInstance*,U32,U32);

U32 f468(wasmcomponentldInstance*,U32,U32,U32);

U32 f469(wasmcomponentldInstance*,U32,U32);

U32 f470(wasmcomponentldInstance*,U32,U32);

U32 f471(wasmcomponentldInstance*,U32);

U32 f472(wasmcomponentldInstance*,U32,U32,U32);

void f473(wasmcomponentldInstance*,U32,U32);

void f474(wasmcomponentldInstance*,U32,U32,U32);

void f475(wasmcomponentldInstance*,U32,U32,U32);

U32 f476(wasmcomponentldInstance*,U32);

void f477(wasmcomponentldInstance*,U32,U32);

void f478(wasmcomponentldInstance*,U32,U32);

void f479(wasmcomponentldInstance*,U32,U32);

void f480(wasmcomponentldInstance*,U32,U32);

void f481(wasmcomponentldInstance*,U32,U32);

void f482(wasmcomponentldInstance*,U32,U32);

void f483(wasmcomponentldInstance*,U32,U32);

void f484(wasmcomponentldInstance*,U32,U32);

void f485(wasmcomponentldInstance*,U32,U32);

void f486(wasmcomponentldInstance*,U32,U32);

U32 f487(wasmcomponentldInstance*,U32,U32);

void f488(wasmcomponentldInstance*,U32,U32);

void f489(wasmcomponentldInstance*,U32,U32,U32);

void f490(wasmcomponentldInstance*,U32,U32);

void f491(wasmcomponentldInstance*,U32,U32);

void f492(wasmcomponentldInstance*,U32,U32);

void f493(wasmcomponentldInstance*,U32,U32);

void f494(wasmcomponentldInstance*,U32,U32);

void f495(wasmcomponentldInstance*,U32,U32);

void f496(wasmcomponentldInstance*,U32,U32);

void f497(wasmcomponentldInstance*,U32,U32,U32);

void f498(wasmcomponentldInstance*,U32,U32);

void f499(wasmcomponentldInstance*,U32,U32);

void f500(wasmcomponentldInstance*,U32,U32);

void f501(wasmcomponentldInstance*,U32,U32);

void f502(wasmcomponentldInstance*,U32,U32);

void f503(wasmcomponentldInstance*,U32,U32);

void f504(wasmcomponentldInstance*,U32,U32);

void f505(wasmcomponentldInstance*,U32,U32);

void f506(wasmcomponentldInstance*,U32,U32);

void f507(wasmcomponentldInstance*,U32,U32);

void f508(wasmcomponentldInstance*,U32,U32);

void f509(wasmcomponentldInstance*,U32,U32);

void f510(wasmcomponentldInstance*,U32,U32);

U32 f511(wasmcomponentldInstance*,U32,U32,U32,U32);

void f512(wasmcomponentldInstance*,U32,U32);

void f513(wasmcomponentldInstance*,U32,U32);

void f514(wasmcomponentldInstance*,U32,U32);

void f515(wasmcomponentldInstance*,U32,U32);

void f516(wasmcomponentldInstance*,U32,U32);

void f517(wasmcomponentldInstance*,U32,U32);

void f518(wasmcomponentldInstance*,U32,U32);

void f519(wasmcomponentldInstance*,U32,U32);

U32 f520(wasmcomponentldInstance*,U32);

void f521(wasmcomponentldInstance*,U32,U32);

void f522(wasmcomponentldInstance*,U32,U32);

void f523(wasmcomponentldInstance*,U32,U32);

void f524(wasmcomponentldInstance*,U32,U32);

U32 f525(wasmcomponentldInstance*,U32,U32);

void f526(wasmcomponentldInstance*,U32,U32);

void f527(wasmcomponentldInstance*,U32,U32);

void f528(wasmcomponentldInstance*,U32,U32);

void f529(wasmcomponentldInstance*,U32,U32);

void f530(wasmcomponentldInstance*,U32,U32);

void f531(wasmcomponentldInstance*,U32,U32);

void f532(wasmcomponentldInstance*,U32,U32);

void f533(wasmcomponentldInstance*,U32,U32);

void f534(wasmcomponentldInstance*,U32,U32);

void f535(wasmcomponentldInstance*,U32,U32);

void f536(wasmcomponentldInstance*,U32,U32);

void f537(wasmcomponentldInstance*,U32,U32);

void f538(wasmcomponentldInstance*,U32,U32,U32);

void f539(wasmcomponentldInstance*,U32,U32);

void f540(wasmcomponentldInstance*,U32,U32);

void f541(wasmcomponentldInstance*,U32,U32);

void f542(wasmcomponentldInstance*,U32,U32);

void f543(wasmcomponentldInstance*,U32,U32);

void f544(wasmcomponentldInstance*,U32,U32);

void f545(wasmcomponentldInstance*,U32,U32);

U32 f546(wasmcomponentldInstance*,U32,U32);

void f547(wasmcomponentldInstance*,U32,U32);

void f548(wasmcomponentldInstance*,U32,U32);

void f549(wasmcomponentldInstance*,U32,U32);

void f550(wasmcomponentldInstance*,U32,U32);

void f551(wasmcomponentldInstance*,U32,U32);

void f552(wasmcomponentldInstance*,U32,U32);

void f553(wasmcomponentldInstance*,U32,U32);

void f554(wasmcomponentldInstance*,U32,U32);

void f555(wasmcomponentldInstance*,U32,U32);

void f556(wasmcomponentldInstance*,U32,U32);

U32 f557(wasmcomponentldInstance*,U32,U32);

void f558(wasmcomponentldInstance*,U32,U32);

void f559(wasmcomponentldInstance*,U32,U32);

void f560(wasmcomponentldInstance*,U32,U32);

void f561(wasmcomponentldInstance*,U32,U32);

void f562(wasmcomponentldInstance*,U32,U32);

void f563(wasmcomponentldInstance*,U32,U32);

void f564(wasmcomponentldInstance*,U32,U32);

void f565(wasmcomponentldInstance*,U32,U32);

void f566(wasmcomponentldInstance*,U32,U32);

void f567(wasmcomponentldInstance*,U32,U32);

void f568(wasmcomponentldInstance*,U32,U32);

U32 f569(wasmcomponentldInstance*,U32,U32);

void f570(wasmcomponentldInstance*,U32,U32);

void f571(wasmcomponentldInstance*,U32,U32);

void f572(wasmcomponentldInstance*,U32,U32);

void f573(wasmcomponentldInstance*,U32,U32);

void f574(wasmcomponentldInstance*,U32,U32);

void f575(wasmcomponentldInstance*,U32,U32);

void f576(wasmcomponentldInstance*,U32,U32);

void f577(wasmcomponentldInstance*,U32,U32);

void f578(wasmcomponentldInstance*,U32,U32);

void f579(wasmcomponentldInstance*,U32,U32);

void f580(wasmcomponentldInstance*,U32,U32);

void f581(wasmcomponentldInstance*,U32,U32);

void f582(wasmcomponentldInstance*,U32,U32);

void f583(wasmcomponentldInstance*,U32,U32);

void f584(wasmcomponentldInstance*,U32,U32);

void f585(wasmcomponentldInstance*,U32,U32);

void f586(wasmcomponentldInstance*,U32,U32);

void f587(wasmcomponentldInstance*,U32,U32);

void f588(wasmcomponentldInstance*,U32,U32);

void f589(wasmcomponentldInstance*,U32,U32);

void f590(wasmcomponentldInstance*,U32,U32);

void f591(wasmcomponentldInstance*,U32,U32);

void f592(wasmcomponentldInstance*,U32,U32);

void f593(wasmcomponentldInstance*,U32,U32);

void f594(wasmcomponentldInstance*,U32,U32,U32);

U32 f595(wasmcomponentldInstance*,U32,U32);

void f596(wasmcomponentldInstance*,U32,U32);

void f597(wasmcomponentldInstance*,U32,U32);

void f598(wasmcomponentldInstance*,U32,U32);

void f599(wasmcomponentldInstance*,U32,U32);

void f600(wasmcomponentldInstance*,U32,U32);

void f601(wasmcomponentldInstance*,U32,U32);

void f602(wasmcomponentldInstance*,U32,U32);

void f603(wasmcomponentldInstance*,U32,U32);

void f604(wasmcomponentldInstance*,U32,U32);

U32 f605(wasmcomponentldInstance*,U32,U32,U32);

void f606(wasmcomponentldInstance*,U32,U32);

void f607(wasmcomponentldInstance*,U32,U32);

void f608(wasmcomponentldInstance*,U32,U32);

void f609(wasmcomponentldInstance*,U32,U32);

void f610(wasmcomponentldInstance*,U32,U32);

void f611(wasmcomponentldInstance*,U32,U32);

void f612(wasmcomponentldInstance*,U32,U32);

U32 f613(wasmcomponentldInstance*,U32,U32,U32);

void f614(wasmcomponentldInstance*,U32,U32);

void f615(wasmcomponentldInstance*,U32,U32);

void f616(wasmcomponentldInstance*,U32,U32);

void f617(wasmcomponentldInstance*,U32,U32);

void f618(wasmcomponentldInstance*,U32,U32);

void f619(wasmcomponentldInstance*,U32,U32);

void f620(wasmcomponentldInstance*,U32,U32);

void f621(wasmcomponentldInstance*,U32,U32);

void f622(wasmcomponentldInstance*,U32,U32);

void f623(wasmcomponentldInstance*,U32,U32,U32);

void f624(wasmcomponentldInstance*,U32,U32);

U32 f625(wasmcomponentldInstance*,U32);

void f626(wasmcomponentldInstance*,U32,U32);

void f627(wasmcomponentldInstance*,U32,U32);

U32 f628(wasmcomponentldInstance*,U32,U32);

void f629(wasmcomponentldInstance*,U32,U32);

void f630(wasmcomponentldInstance*,U32,U32);

void f631(wasmcomponentldInstance*,U32,U32);

void f632(wasmcomponentldInstance*,U32,U32);

void f633(wasmcomponentldInstance*,U32,U32);

void f634(wasmcomponentldInstance*,U32,U32);

void f635(wasmcomponentldInstance*,U32,U32);

void f636(wasmcomponentldInstance*,U32,U32);

void f637(wasmcomponentldInstance*,U32,U32);

void f638(wasmcomponentldInstance*,U32,U32);

void f639(wasmcomponentldInstance*,U32,U32);

void f640(wasmcomponentldInstance*,U32,U32);

void f641(wasmcomponentldInstance*,U32,U32);

void f642(wasmcomponentldInstance*,U32,U32);

void f643(wasmcomponentldInstance*,U32,U32);

void f644(wasmcomponentldInstance*,U32,U32);

void f645(wasmcomponentldInstance*,U32,U32);

void f646(wasmcomponentldInstance*,U32,U32);

void f647(wasmcomponentldInstance*,U32,U32);

void f648(wasmcomponentldInstance*,U32,U32);

void f649(wasmcomponentldInstance*,U32,U32);

void f650(wasmcomponentldInstance*,U32,U32);

void f651(wasmcomponentldInstance*,U32,U32);

void f652(wasmcomponentldInstance*,U32,U32);

void f653(wasmcomponentldInstance*,U32,U32);

void f654(wasmcomponentldInstance*,U32,U32);

void f655(wasmcomponentldInstance*,U32,U32);

void f656(wasmcomponentldInstance*,U32,U32);

void f657(wasmcomponentldInstance*,U32,U32);

void f658(wasmcomponentldInstance*,U32,U32);

void f659(wasmcomponentldInstance*,U32,U32);

void f660(wasmcomponentldInstance*,U32,U32);

void f661(wasmcomponentldInstance*,U32,U32);

void f662(wasmcomponentldInstance*,U32,U32);

void f663(wasmcomponentldInstance*,U32,U32);

void f664(wasmcomponentldInstance*,U32,U32);

void f665(wasmcomponentldInstance*,U32,U32);

void f666(wasmcomponentldInstance*,U32,U32);

void f667(wasmcomponentldInstance*,U32,U32);

void f668(wasmcomponentldInstance*,U32,U32);

void f669(wasmcomponentldInstance*,U32,U32);

void f670(wasmcomponentldInstance*,U32,U32);

void f671(wasmcomponentldInstance*,U32,U32);

void f672(wasmcomponentldInstance*,U32,U32);

void f673(wasmcomponentldInstance*,U32,U32);

void f674(wasmcomponentldInstance*,U32,U32);

void f675(wasmcomponentldInstance*,U32,U32);

void f676(wasmcomponentldInstance*,U32,U32);

void f677(wasmcomponentldInstance*,U32,U32);

void f678(wasmcomponentldInstance*,U32,U32);

void f679(wasmcomponentldInstance*,U32,U32);

void f680(wasmcomponentldInstance*,U32,U32);

void f681(wasmcomponentldInstance*,U32,U32);

void f682(wasmcomponentldInstance*,U32,U32);

void f683(wasmcomponentldInstance*,U32,U32);

void f684(wasmcomponentldInstance*,U32,U32);

void f685(wasmcomponentldInstance*,U32,U32);

void f686(wasmcomponentldInstance*,U32,U32);

void f687(wasmcomponentldInstance*,U32,U32);

void f688(wasmcomponentldInstance*,U32,U32);

void f689(wasmcomponentldInstance*,U32,U32);

void f690(wasmcomponentldInstance*,U32,U32);

void f691(wasmcomponentldInstance*,U32,U32);

void f692(wasmcomponentldInstance*,U32,U32);

void f693(wasmcomponentldInstance*,U32,U32);

void f694(wasmcomponentldInstance*,U32,U32);

void f695(wasmcomponentldInstance*,U32,U32);

void f696(wasmcomponentldInstance*,U32,U32);

void f697(wasmcomponentldInstance*,U32,U32);

void f698(wasmcomponentldInstance*,U32,U32);

void f699(wasmcomponentldInstance*,U32,U32);

void f700(wasmcomponentldInstance*,U32,U32);

void f701(wasmcomponentldInstance*,U32,U32);

void f702(wasmcomponentldInstance*,U32,U32,U32);

void f703(wasmcomponentldInstance*,U32,U32);

void f704(wasmcomponentldInstance*,U32,U32);

void f705(wasmcomponentldInstance*,U32,U32);

void f706(wasmcomponentldInstance*,U32,U32);

void f707(wasmcomponentldInstance*,U32,U32);

void f708(wasmcomponentldInstance*,U32,U32);

void f709(wasmcomponentldInstance*,U32,U32);

void f710(wasmcomponentldInstance*,U32,U32);

void f711(wasmcomponentldInstance*,U32,U32);

void f712(wasmcomponentldInstance*,U32,U32);

void f713(wasmcomponentldInstance*,U32,U32);

void f714(wasmcomponentldInstance*,U32,U32);

void f715(wasmcomponentldInstance*,U32,U32);

void f716(wasmcomponentldInstance*,U32,U32);

void f717(wasmcomponentldInstance*,U32,U32);

void f718(wasmcomponentldInstance*,U32,U32);

void f719(wasmcomponentldInstance*,U32,U32);

void f720(wasmcomponentldInstance*,U32,U32);

void f721(wasmcomponentldInstance*,U32,U32);

void f722(wasmcomponentldInstance*,U32,U32);

void f723(wasmcomponentldInstance*,U32,U32);

void f724(wasmcomponentldInstance*,U32,U32);

void f725(wasmcomponentldInstance*,U32,U32);

void f726(wasmcomponentldInstance*,U32,U32);

void f727(wasmcomponentldInstance*,U32,U32);

void f728(wasmcomponentldInstance*,U32,U32);

void f729(wasmcomponentldInstance*,U32,U32);

void f730(wasmcomponentldInstance*,U32,U32);

void f731(wasmcomponentldInstance*,U32,U32);

void f732(wasmcomponentldInstance*,U32,U32);

void f733(wasmcomponentldInstance*,U32,U32);

void f734(wasmcomponentldInstance*,U32,U32);

void f735(wasmcomponentldInstance*,U32,U32);

void f736(wasmcomponentldInstance*,U32,U32);

void f737(wasmcomponentldInstance*,U32,U32);

void f738(wasmcomponentldInstance*,U32,U32);

void f739(wasmcomponentldInstance*,U32,U32);

void f740(wasmcomponentldInstance*,U32,U32);

void f741(wasmcomponentldInstance*,U32,U32);

void f742(wasmcomponentldInstance*,U32,U32);

void f743(wasmcomponentldInstance*,U32,U32);

void f744(wasmcomponentldInstance*,U32,U32);

void f745(wasmcomponentldInstance*,U32,U32,U32);

U32 f746(wasmcomponentldInstance*,U32);

void f747(wasmcomponentldInstance*,U32,U32);

void f748(wasmcomponentldInstance*,U32,U32);

void f749(wasmcomponentldInstance*,U32,U32);

void f750(wasmcomponentldInstance*,U32,U32);

void f751(wasmcomponentldInstance*,U32,U32);

void f752(wasmcomponentldInstance*,U32,U32);

void f753(wasmcomponentldInstance*,U32,U32);

void f754(wasmcomponentldInstance*,U32,U32);

void f755(wasmcomponentldInstance*,U32,U32);

void f756(wasmcomponentldInstance*,U32,U32);

void f757(wasmcomponentldInstance*,U32,U32);

void f758(wasmcomponentldInstance*,U32,U32);

void f759(wasmcomponentldInstance*,U32,U32);

void f760(wasmcomponentldInstance*,U32,U32);

void f761(wasmcomponentldInstance*,U32,U32);

void f762(wasmcomponentldInstance*,U32,U32);

void f763(wasmcomponentldInstance*,U32,U32);

void f764(wasmcomponentldInstance*,U32,U32);

void f765(wasmcomponentldInstance*,U32,U32);

void f766(wasmcomponentldInstance*,U32,U32);

void f767(wasmcomponentldInstance*,U32,U32);

void f768(wasmcomponentldInstance*,U32,U32);

void f769(wasmcomponentldInstance*,U32,U32);

void f770(wasmcomponentldInstance*,U32,U32);

void f771(wasmcomponentldInstance*,U32,U32);

void f772(wasmcomponentldInstance*,U32,U32);

void f773(wasmcomponentldInstance*,U32,U32);

void f774(wasmcomponentldInstance*,U32,U32);

void f775(wasmcomponentldInstance*,U32,U32);

void f776(wasmcomponentldInstance*,U32,U32);

void f777(wasmcomponentldInstance*,U32,U32);

void f778(wasmcomponentldInstance*,U32,U32);

void f779(wasmcomponentldInstance*,U32,U32);

void f780(wasmcomponentldInstance*,U32,U32);

void f781(wasmcomponentldInstance*,U32,U32);

void f782(wasmcomponentldInstance*,U32,U32);

void f783(wasmcomponentldInstance*,U32,U32);

void f784(wasmcomponentldInstance*,U32,U32);

void f785(wasmcomponentldInstance*,U32,U32);

void f786(wasmcomponentldInstance*,U32,U32);

void f787(wasmcomponentldInstance*,U32,U32);

void f788(wasmcomponentldInstance*,U32,U32);

void f789(wasmcomponentldInstance*,U32,U32);

void f790(wasmcomponentldInstance*,U32,U32);

void f791(wasmcomponentldInstance*,U32,U32);

void f792(wasmcomponentldInstance*,U32,U32);

void f793(wasmcomponentldInstance*,U32,U32);

void f794(wasmcomponentldInstance*,U32,U32);

void f795(wasmcomponentldInstance*,U32,U32);

U32 f796(wasmcomponentldInstance*,U32,U32);

U32 f797(wasmcomponentldInstance*,U32);

void f798(wasmcomponentldInstance*,U32,U32,U32,U32);

void f799(wasmcomponentldInstance*,U32);

void f800(wasmcomponentldInstance*,U32,U32);

void f801(wasmcomponentldInstance*,U32,U32);

void f802(wasmcomponentldInstance*,U32,U32);

void f803(wasmcomponentldInstance*,U32,U32);

void f804(wasmcomponentldInstance*,U32,U32);

void f805(wasmcomponentldInstance*,U32,U32);

void f806(wasmcomponentldInstance*,U32,U32);

void f807(wasmcomponentldInstance*,U32,U32);

void f808(wasmcomponentldInstance*,U32,U32);

void f809(wasmcomponentldInstance*,U32,U32);

void f810(wasmcomponentldInstance*,U32,U32);

void f811(wasmcomponentldInstance*,U32,U32);

void f812(wasmcomponentldInstance*,U32,U32);

void f813(wasmcomponentldInstance*,U32,U32);

void f814(wasmcomponentldInstance*,U32,U32);

void f815(wasmcomponentldInstance*,U32,U32);

void f816(wasmcomponentldInstance*,U32,U32);

void f817(wasmcomponentldInstance*,U32,U32);

void f818(wasmcomponentldInstance*,U32,U32);

void f819(wasmcomponentldInstance*,U32,U32);

void f820(wasmcomponentldInstance*,U32,U32);

void f821(wasmcomponentldInstance*,U32,U32);

void f822(wasmcomponentldInstance*,U32,U32);

void f823(wasmcomponentldInstance*,U32,U32);

void f824(wasmcomponentldInstance*,U32,U32);

void f825(wasmcomponentldInstance*,U32,U32);

void f826(wasmcomponentldInstance*,U32,U32);

void f827(wasmcomponentldInstance*,U32,U32);

void f828(wasmcomponentldInstance*,U32,U32);

void f829(wasmcomponentldInstance*,U32,U32);

void f830(wasmcomponentldInstance*,U32,U32);

void f831(wasmcomponentldInstance*,U32,U32);

void f832(wasmcomponentldInstance*,U32,U32);

void f833(wasmcomponentldInstance*,U32,U32);

void f834(wasmcomponentldInstance*,U32,U32);

void f835(wasmcomponentldInstance*,U32,U32);

void f836(wasmcomponentldInstance*,U32,U32);

void f837(wasmcomponentldInstance*,U32,U32);

void f838(wasmcomponentldInstance*,U32,U32);

void f839(wasmcomponentldInstance*,U32,U32);

void f840(wasmcomponentldInstance*,U32,U32);

void f841(wasmcomponentldInstance*,U32,U32);

void f842(wasmcomponentldInstance*,U32,U32);

void f843(wasmcomponentldInstance*,U32,U32);

void f844(wasmcomponentldInstance*,U32,U32);

void f845(wasmcomponentldInstance*,U32,U32);

void f846(wasmcomponentldInstance*,U32,U32);

void f847(wasmcomponentldInstance*,U32,U32);

void f848(wasmcomponentldInstance*,U32,U32);

void f849(wasmcomponentldInstance*,U32,U32);

void f850(wasmcomponentldInstance*,U32,U32);

void f851(wasmcomponentldInstance*,U32,U32);

void f852(wasmcomponentldInstance*,U32,U32);

void f853(wasmcomponentldInstance*,U32,U32);

void f854(wasmcomponentldInstance*,U32,U32);

void f855(wasmcomponentldInstance*,U32,U32);

void f856(wasmcomponentldInstance*,U32,U32);

void f857(wasmcomponentldInstance*,U32,U32);

void f858(wasmcomponentldInstance*,U32,U32);

void f859(wasmcomponentldInstance*,U32,U32);

void f860(wasmcomponentldInstance*,U32,U32);

void f861(wasmcomponentldInstance*,U32,U32);

void f862(wasmcomponentldInstance*,U32,U32);

void f863(wasmcomponentldInstance*,U32,U32);

void f864(wasmcomponentldInstance*,U32,U32);

void f865(wasmcomponentldInstance*,U32,U32);

void f866(wasmcomponentldInstance*,U32,U32);

void f867(wasmcomponentldInstance*,U32,U32);

void f868(wasmcomponentldInstance*,U32,U32);

void f869(wasmcomponentldInstance*,U32,U32);

void f870(wasmcomponentldInstance*,U32,U32);

void f871(wasmcomponentldInstance*,U32,U32);

void f872(wasmcomponentldInstance*,U32,U32);

void f873(wasmcomponentldInstance*,U32,U32);

void f874(wasmcomponentldInstance*,U32,U32);

void f875(wasmcomponentldInstance*,U32,U32);

void f876(wasmcomponentldInstance*,U32,U32);

void f877(wasmcomponentldInstance*,U32,U32);

void f878(wasmcomponentldInstance*,U32,U32);

void f879(wasmcomponentldInstance*,U32,U32);

void f880(wasmcomponentldInstance*,U32,U32);

void f881(wasmcomponentldInstance*,U32,U32);

void f882(wasmcomponentldInstance*,U32,U32);

void f883(wasmcomponentldInstance*,U32,U32);

void f884(wasmcomponentldInstance*,U32,U32);

void f885(wasmcomponentldInstance*,U32,U32);

void f886(wasmcomponentldInstance*,U32,U32);

void f887(wasmcomponentldInstance*,U32,U32);

void f888(wasmcomponentldInstance*,U32,U32);

void f889(wasmcomponentldInstance*,U32,U32);

void f890(wasmcomponentldInstance*,U32,U32);

void f891(wasmcomponentldInstance*,U32,U32);

void f892(wasmcomponentldInstance*,U32,U32);

void f893(wasmcomponentldInstance*,U32,U32);

void f894(wasmcomponentldInstance*,U32,U32);

void f895(wasmcomponentldInstance*,U32,U32);

void f896(wasmcomponentldInstance*,U32,U32);

void f897(wasmcomponentldInstance*,U32,U32);

void f898(wasmcomponentldInstance*,U32,U32);

void f899(wasmcomponentldInstance*,U32,U32);

void f900(wasmcomponentldInstance*,U32,U32);

void f901(wasmcomponentldInstance*,U32,U32);

void f902(wasmcomponentldInstance*,U32,U32);

void f903(wasmcomponentldInstance*,U32,U32);

void f904(wasmcomponentldInstance*,U32,U32);

void f905(wasmcomponentldInstance*,U32,U32);

void f906(wasmcomponentldInstance*,U32,U32);

void f907(wasmcomponentldInstance*,U32,U32);

void f908(wasmcomponentldInstance*,U32,U32);

void f909(wasmcomponentldInstance*,U32,U32);

void f910(wasmcomponentldInstance*,U32,U32);

void f911(wasmcomponentldInstance*,U32,U32);

void f912(wasmcomponentldInstance*,U32,U32);

void f913(wasmcomponentldInstance*,U32,U32);

void f914(wasmcomponentldInstance*,U32,U32);

void f915(wasmcomponentldInstance*,U32,U32);

void f916(wasmcomponentldInstance*,U32,U32);

void f917(wasmcomponentldInstance*,U32,U32);

void f918(wasmcomponentldInstance*,U32,U32);

void f919(wasmcomponentldInstance*,U32,U32);

void f920(wasmcomponentldInstance*,U32,U32);

void f921(wasmcomponentldInstance*,U32,U32);

void f922(wasmcomponentldInstance*,U32,U32);

void f923(wasmcomponentldInstance*,U32,U32);

void f924(wasmcomponentldInstance*,U32,U32);

void f925(wasmcomponentldInstance*,U32,U32);

void f926(wasmcomponentldInstance*,U32,U32);

void f927(wasmcomponentldInstance*,U32,U32);

void f928(wasmcomponentldInstance*,U32,U32);

void f929(wasmcomponentldInstance*,U32,U32);

void f930(wasmcomponentldInstance*,U32,U32);

void f931(wasmcomponentldInstance*,U32,U32);

void f932(wasmcomponentldInstance*,U32,U32);

void f933(wasmcomponentldInstance*,U32,U32);

void f934(wasmcomponentldInstance*,U32,U32);

void f935(wasmcomponentldInstance*,U32,U32);

void f936(wasmcomponentldInstance*,U32,U32);

void f937(wasmcomponentldInstance*,U32,U32);

void f938(wasmcomponentldInstance*,U32,U32);

void f939(wasmcomponentldInstance*,U32,U32);

void f940(wasmcomponentldInstance*,U32,U32);

void f941(wasmcomponentldInstance*,U32,U32);

void f942(wasmcomponentldInstance*,U32,U32);

void f943(wasmcomponentldInstance*,U32,U32);

void f944(wasmcomponentldInstance*,U32,U32);

void f945(wasmcomponentldInstance*,U32,U32);

void f946(wasmcomponentldInstance*,U32,U32);

void f947(wasmcomponentldInstance*,U32,U32);

void f948(wasmcomponentldInstance*,U32,U32);

void f949(wasmcomponentldInstance*,U32,U32);

void f950(wasmcomponentldInstance*,U32,U32);

void f951(wasmcomponentldInstance*,U32,U32);

void f952(wasmcomponentldInstance*,U32,U32);

void f953(wasmcomponentldInstance*,U32,U32);

void f954(wasmcomponentldInstance*,U32,U32);

void f955(wasmcomponentldInstance*,U32,U32);

void f956(wasmcomponentldInstance*,U32,U32);

void f957(wasmcomponentldInstance*,U32,U32);

void f958(wasmcomponentldInstance*,U32,U32);

void f959(wasmcomponentldInstance*,U32,U32);

void f960(wasmcomponentldInstance*,U32,U32);

void f961(wasmcomponentldInstance*,U32,U32);

void f962(wasmcomponentldInstance*,U32,U32);

void f963(wasmcomponentldInstance*,U32,U32);

void f964(wasmcomponentldInstance*,U32,U32);

void f965(wasmcomponentldInstance*,U32,U32);

void f966(wasmcomponentldInstance*,U32,U32);

void f967(wasmcomponentldInstance*,U32,U32);

void f968(wasmcomponentldInstance*,U32,U32);

void f969(wasmcomponentldInstance*,U32,U32);

void f970(wasmcomponentldInstance*,U32,U32);

void f971(wasmcomponentldInstance*,U32,U32);

void f972(wasmcomponentldInstance*,U32,U32);

void f973(wasmcomponentldInstance*,U32,U32);

void f974(wasmcomponentldInstance*,U32,U32);

void f975(wasmcomponentldInstance*,U32,U32);

void f976(wasmcomponentldInstance*,U32,U32);

void f977(wasmcomponentldInstance*,U32,U32);

void f978(wasmcomponentldInstance*,U32,U32);

void f979(wasmcomponentldInstance*,U32,U32);

void f980(wasmcomponentldInstance*,U32,U32);

void f981(wasmcomponentldInstance*,U32,U32);

void f982(wasmcomponentldInstance*,U32,U32);

void f983(wasmcomponentldInstance*,U32,U32);

void f984(wasmcomponentldInstance*,U32,U32);

void f985(wasmcomponentldInstance*,U32,U32);

void f986(wasmcomponentldInstance*,U32,U32);

void f987(wasmcomponentldInstance*,U32,U32);

void f988(wasmcomponentldInstance*,U32,U32);

void f989(wasmcomponentldInstance*,U32,U32);

void f990(wasmcomponentldInstance*,U32,U32);

void f991(wasmcomponentldInstance*,U32,U32);

void f992(wasmcomponentldInstance*,U32,U32);

void f993(wasmcomponentldInstance*,U32,U32);

void f994(wasmcomponentldInstance*,U32,U32);

void f995(wasmcomponentldInstance*,U32,U32);

void f996(wasmcomponentldInstance*,U32,U32);

void f997(wasmcomponentldInstance*,U32,U32);

void f998(wasmcomponentldInstance*,U32,U32);

void f999(wasmcomponentldInstance*,U32,U32);

void f1000(wasmcomponentldInstance*,U32,U32);

void f1001(wasmcomponentldInstance*,U32,U32);

void f1002(wasmcomponentldInstance*,U32,U32);

void f1003(wasmcomponentldInstance*,U32,U32);

void f1004(wasmcomponentldInstance*,U32,U32);

void f1005(wasmcomponentldInstance*,U32,U32);

void f1006(wasmcomponentldInstance*,U32,U32);

void f1007(wasmcomponentldInstance*,U32,U32);

void f1008(wasmcomponentldInstance*,U32,U32);

void f1009(wasmcomponentldInstance*,U32,U32);

void f1010(wasmcomponentldInstance*,U32,U32);

void f1011(wasmcomponentldInstance*,U32,U32);

void f1012(wasmcomponentldInstance*,U32,U32);

void f1013(wasmcomponentldInstance*,U32,U32);

void f1014(wasmcomponentldInstance*,U32,U32);

void f1015(wasmcomponentldInstance*,U32,U32);

void f1016(wasmcomponentldInstance*,U32,U32);

void f1017(wasmcomponentldInstance*,U32,U32);

void f1018(wasmcomponentldInstance*,U32,U32);

void f1019(wasmcomponentldInstance*,U32,U32);

void f1020(wasmcomponentldInstance*,U32,U32);

void f1021(wasmcomponentldInstance*,U32,U32);

void f1022(wasmcomponentldInstance*,U32,U32);

void f1023(wasmcomponentldInstance*,U32,U32);

void f1024(wasmcomponentldInstance*,U32,U32);

void f1025(wasmcomponentldInstance*,U32,U32);

void f1026(wasmcomponentldInstance*,U32,U32);

void f1027(wasmcomponentldInstance*,U32,U32);

void f1028(wasmcomponentldInstance*,U32,U32);

void f1029(wasmcomponentldInstance*,U32,U32);

void f1030(wasmcomponentldInstance*,U32,U32);

void f1031(wasmcomponentldInstance*,U32,U32);

void f1032(wasmcomponentldInstance*,U32,U32);

void f1033(wasmcomponentldInstance*,U32,U32);

void f1034(wasmcomponentldInstance*,U32,U32);

void f1035(wasmcomponentldInstance*,U32,U32);

void f1036(wasmcomponentldInstance*,U32,U32);

void f1037(wasmcomponentldInstance*,U32,U32);

void f1038(wasmcomponentldInstance*,U32,U32);

void f1039(wasmcomponentldInstance*,U32,U32);

void f1040(wasmcomponentldInstance*,U32,U32);

void f1041(wasmcomponentldInstance*,U32,U32);

void f1042(wasmcomponentldInstance*,U32,U32);

void f1043(wasmcomponentldInstance*,U32,U32);

void f1044(wasmcomponentldInstance*,U32,U32);

void f1045(wasmcomponentldInstance*,U32,U32);

void f1046(wasmcomponentldInstance*,U32,U32);

void f1047(wasmcomponentldInstance*,U32,U32);

void f1048(wasmcomponentldInstance*,U32,U32);

void f1049(wasmcomponentldInstance*,U32,U32);

void f1050(wasmcomponentldInstance*,U32,U32);

void f1051(wasmcomponentldInstance*,U32,U32);

void f1052(wasmcomponentldInstance*,U32,U32);

void f1053(wasmcomponentldInstance*,U32,U32);

void f1054(wasmcomponentldInstance*,U32,U32);

void f1055(wasmcomponentldInstance*,U32,U32);

void f1056(wasmcomponentldInstance*,U32,U32);

void f1057(wasmcomponentldInstance*,U32,U32);

void f1058(wasmcomponentldInstance*,U32,U32);

void f1059(wasmcomponentldInstance*,U32,U32);

void f1060(wasmcomponentldInstance*,U32,U32);

void f1061(wasmcomponentldInstance*,U32,U32);

void f1062(wasmcomponentldInstance*,U32,U32);

void f1063(wasmcomponentldInstance*,U32,U32);

void f1064(wasmcomponentldInstance*,U32,U32);

void f1065(wasmcomponentldInstance*,U32,U32);

void f1066(wasmcomponentldInstance*,U32,U32);

void f1067(wasmcomponentldInstance*,U32,U32);

void f1068(wasmcomponentldInstance*,U32,U32);

void f1069(wasmcomponentldInstance*,U32,U32);

void f1070(wasmcomponentldInstance*,U32,U32);

void f1071(wasmcomponentldInstance*,U32,U32);

void f1072(wasmcomponentldInstance*,U32,U32);

void f1073(wasmcomponentldInstance*,U32,U32);

void f1074(wasmcomponentldInstance*,U32,U32);

void f1075(wasmcomponentldInstance*,U32,U32);

void f1076(wasmcomponentldInstance*,U32,U32);

void f1077(wasmcomponentldInstance*,U32,U32);

void f1078(wasmcomponentldInstance*,U32,U32);

void f1079(wasmcomponentldInstance*,U32,U32);

void f1080(wasmcomponentldInstance*,U32,U32);

void f1081(wasmcomponentldInstance*,U32,U32);

void f1082(wasmcomponentldInstance*,U32,U32);

void f1083(wasmcomponentldInstance*,U32,U32);

void f1084(wasmcomponentldInstance*,U32,U32);

void f1085(wasmcomponentldInstance*,U32,U32);

void f1086(wasmcomponentldInstance*,U32,U32);

void f1087(wasmcomponentldInstance*,U32,U32);

void f1088(wasmcomponentldInstance*,U32,U32);

void f1089(wasmcomponentldInstance*,U32,U32);

void f1090(wasmcomponentldInstance*,U32,U32);

void f1091(wasmcomponentldInstance*,U32,U32);

void f1092(wasmcomponentldInstance*,U32,U32);

void f1093(wasmcomponentldInstance*,U32,U32);

void f1094(wasmcomponentldInstance*,U32,U32);

void f1095(wasmcomponentldInstance*,U32,U32);

void f1096(wasmcomponentldInstance*,U32,U32);

void f1097(wasmcomponentldInstance*,U32,U32);

void f1098(wasmcomponentldInstance*,U32,U32);

void f1099(wasmcomponentldInstance*,U32,U32);

void f1100(wasmcomponentldInstance*,U32,U32);

void f1101(wasmcomponentldInstance*,U32,U32);

void f1102(wasmcomponentldInstance*,U32,U32);

void f1103(wasmcomponentldInstance*,U32,U32);

void f1104(wasmcomponentldInstance*,U32,U32);

void f1105(wasmcomponentldInstance*,U32,U32);

void f1106(wasmcomponentldInstance*,U32,U32);

void f1107(wasmcomponentldInstance*,U32,U32);

void f1108(wasmcomponentldInstance*,U32,U32);

void f1109(wasmcomponentldInstance*,U32,U32);

void f1110(wasmcomponentldInstance*,U32,U32);

void f1111(wasmcomponentldInstance*,U32,U32);

void f1112(wasmcomponentldInstance*,U32,U32);

void f1113(wasmcomponentldInstance*,U32,U32);

void f1114(wasmcomponentldInstance*,U32,U32);

void f1115(wasmcomponentldInstance*,U32,U32);

void f1116(wasmcomponentldInstance*,U32,U32);

void f1117(wasmcomponentldInstance*,U32,U32);

void f1118(wasmcomponentldInstance*,U32,U32);

void f1119(wasmcomponentldInstance*,U32,U32);

void f1120(wasmcomponentldInstance*,U32,U32);

void f1121(wasmcomponentldInstance*,U32,U32);

void f1122(wasmcomponentldInstance*,U32,U32);

void f1123(wasmcomponentldInstance*,U32,U32);

void f1124(wasmcomponentldInstance*,U32,U32);

void f1125(wasmcomponentldInstance*,U32,U32);

void f1126(wasmcomponentldInstance*,U32,U32);

void f1127(wasmcomponentldInstance*,U32,U32);

void f1128(wasmcomponentldInstance*,U32,U32);

void f1129(wasmcomponentldInstance*,U32,U32);

void f1130(wasmcomponentldInstance*,U32,U32);

void f1131(wasmcomponentldInstance*,U32,U32);

void f1132(wasmcomponentldInstance*,U32,U32);

void f1133(wasmcomponentldInstance*,U32,U32);

void f1134(wasmcomponentldInstance*,U32,U32);

void f1135(wasmcomponentldInstance*,U32,U32);

void f1136(wasmcomponentldInstance*,U32,U32);

void f1137(wasmcomponentldInstance*,U32,U32);

void f1138(wasmcomponentldInstance*,U32,U32);

void f1139(wasmcomponentldInstance*,U32,U32);

void f1140(wasmcomponentldInstance*,U32,U32);

void f1141(wasmcomponentldInstance*,U32,U32);

void f1142(wasmcomponentldInstance*,U32,U32);

void f1143(wasmcomponentldInstance*,U32,U32);

void f1144(wasmcomponentldInstance*,U32,U32);

void f1145(wasmcomponentldInstance*,U32,U32);

void f1146(wasmcomponentldInstance*,U32,U32);

void f1147(wasmcomponentldInstance*,U32,U32);

void f1148(wasmcomponentldInstance*,U32,U32);

void f1149(wasmcomponentldInstance*,U32,U32);

void f1150(wasmcomponentldInstance*,U32,U32);

void f1151(wasmcomponentldInstance*,U32,U32);

void f1152(wasmcomponentldInstance*,U32,U32);

void f1153(wasmcomponentldInstance*,U32,U32);

void f1154(wasmcomponentldInstance*,U32,U32);

void f1155(wasmcomponentldInstance*,U32,U32);

void f1156(wasmcomponentldInstance*,U32,U32);

void f1157(wasmcomponentldInstance*,U32,U32);

void f1158(wasmcomponentldInstance*,U32,U32);

void f1159(wasmcomponentldInstance*,U32,U32);

void f1160(wasmcomponentldInstance*,U32,U32);

void f1161(wasmcomponentldInstance*,U32,U32);

void f1162(wasmcomponentldInstance*,U32,U32);

void f1163(wasmcomponentldInstance*,U32,U32);

void f1164(wasmcomponentldInstance*,U32,U32);

void f1165(wasmcomponentldInstance*,U32,U32);

void f1166(wasmcomponentldInstance*,U32,U32);

void f1167(wasmcomponentldInstance*,U32,U32);

void f1168(wasmcomponentldInstance*,U32,U32);

void f1169(wasmcomponentldInstance*,U32,U32);

void f1170(wasmcomponentldInstance*,U32,U32);

void f1171(wasmcomponentldInstance*,U32,U32);

void f1172(wasmcomponentldInstance*,U32,U32);

void f1173(wasmcomponentldInstance*,U32,U32);

void f1174(wasmcomponentldInstance*,U32,U32);

void f1175(wasmcomponentldInstance*,U32,U32);

void f1176(wasmcomponentldInstance*,U32,U32);

void f1177(wasmcomponentldInstance*,U32,U32);

void f1178(wasmcomponentldInstance*,U32,U32);

void f1179(wasmcomponentldInstance*,U32,U32);

void f1180(wasmcomponentldInstance*,U32,U32);

void f1181(wasmcomponentldInstance*,U32,U32);

void f1182(wasmcomponentldInstance*,U32,U32);

void f1183(wasmcomponentldInstance*,U32,U32);

void f1184(wasmcomponentldInstance*,U32,U32);

void f1185(wasmcomponentldInstance*,U32,U32);

void f1186(wasmcomponentldInstance*,U32,U32);

void f1187(wasmcomponentldInstance*,U32,U32);

void f1188(wasmcomponentldInstance*,U32,U32);

void f1189(wasmcomponentldInstance*,U32,U32);

void f1190(wasmcomponentldInstance*,U32,U32);

void f1191(wasmcomponentldInstance*,U32,U32);

void f1192(wasmcomponentldInstance*,U32,U32);

void f1193(wasmcomponentldInstance*,U32,U32);

void f1194(wasmcomponentldInstance*,U32,U32);

void f1195(wasmcomponentldInstance*,U32,U32);

void f1196(wasmcomponentldInstance*,U32,U32);

void f1197(wasmcomponentldInstance*,U32,U32);

void f1198(wasmcomponentldInstance*,U32,U32);

void f1199(wasmcomponentldInstance*,U32,U32);

void f1200(wasmcomponentldInstance*,U32,U32);

void f1201(wasmcomponentldInstance*,U32,U32);

void f1202(wasmcomponentldInstance*,U32,U32);

void f1203(wasmcomponentldInstance*,U32,U32);

void f1204(wasmcomponentldInstance*,U32,U32);

void f1205(wasmcomponentldInstance*,U32,U32);

void f1206(wasmcomponentldInstance*,U32,U32);

void f1207(wasmcomponentldInstance*,U32,U32);

void f1208(wasmcomponentldInstance*,U32,U32);

void f1209(wasmcomponentldInstance*,U32,U32);

void f1210(wasmcomponentldInstance*,U32,U32);

void f1211(wasmcomponentldInstance*,U32,U32);

void f1212(wasmcomponentldInstance*,U32,U32);

void f1213(wasmcomponentldInstance*,U32,U32);

void f1214(wasmcomponentldInstance*,U32,U32);

void f1215(wasmcomponentldInstance*,U32,U32);

void f1216(wasmcomponentldInstance*,U32,U32);

void f1217(wasmcomponentldInstance*,U32,U32);

void f1218(wasmcomponentldInstance*,U32,U32);

void f1219(wasmcomponentldInstance*,U32,U32);

void f1220(wasmcomponentldInstance*,U32,U32);

void f1221(wasmcomponentldInstance*,U32,U32);

void f1222(wasmcomponentldInstance*,U32,U32);

void f1223(wasmcomponentldInstance*,U32,U32);

void f1224(wasmcomponentldInstance*,U32,U32);

void f1225(wasmcomponentldInstance*,U32,U32);

void f1226(wasmcomponentldInstance*,U32,U32);

void f1227(wasmcomponentldInstance*,U32,U32);

void f1228(wasmcomponentldInstance*,U32,U32);

void f1229(wasmcomponentldInstance*,U32,U32);

void f1230(wasmcomponentldInstance*,U32,U32);

void f1231(wasmcomponentldInstance*,U32,U32);

void f1232(wasmcomponentldInstance*,U32,U32);

void f1233(wasmcomponentldInstance*,U32,U32);

void f1234(wasmcomponentldInstance*,U32,U32);

void f1235(wasmcomponentldInstance*,U32,U32);

void f1236(wasmcomponentldInstance*,U32,U32);

void f1237(wasmcomponentldInstance*,U32,U32);

void f1238(wasmcomponentldInstance*,U32,U32);

void f1239(wasmcomponentldInstance*,U32,U32);

void f1240(wasmcomponentldInstance*,U32,U32);

void f1241(wasmcomponentldInstance*,U32,U32);

void f1242(wasmcomponentldInstance*,U32,U32);

void f1243(wasmcomponentldInstance*,U32,U32);

void f1244(wasmcomponentldInstance*,U32,U32);

void f1245(wasmcomponentldInstance*,U32,U32);

void f1246(wasmcomponentldInstance*,U32,U32);

void f1247(wasmcomponentldInstance*,U32,U32);

void f1248(wasmcomponentldInstance*,U32,U32);

void f1249(wasmcomponentldInstance*,U32,U32);

void f1250(wasmcomponentldInstance*,U32,U32);

void f1251(wasmcomponentldInstance*,U32,U32);

void f1252(wasmcomponentldInstance*,U32,U32);

void f1253(wasmcomponentldInstance*,U32,U32);

void f1254(wasmcomponentldInstance*,U32,U32);

void f1255(wasmcomponentldInstance*,U32,U32);

void f1256(wasmcomponentldInstance*,U32,U32);

void f1257(wasmcomponentldInstance*,U32,U32);

void f1258(wasmcomponentldInstance*,U32,U32);

void f1259(wasmcomponentldInstance*,U32,U32);

void f1260(wasmcomponentldInstance*,U32,U32);

void f1261(wasmcomponentldInstance*,U32,U32);

void f1262(wasmcomponentldInstance*,U32,U32);

void f1263(wasmcomponentldInstance*,U32,U32);

void f1264(wasmcomponentldInstance*,U32,U32);

void f1265(wasmcomponentldInstance*,U32,U32);

void f1266(wasmcomponentldInstance*,U32,U32);

void f1267(wasmcomponentldInstance*,U32,U32);

void f1268(wasmcomponentldInstance*,U32,U32);

void f1269(wasmcomponentldInstance*,U32,U32);

void f1270(wasmcomponentldInstance*,U32,U32);

void f1271(wasmcomponentldInstance*,U32,U32);

void f1272(wasmcomponentldInstance*,U32,U32);

void f1273(wasmcomponentldInstance*,U32);

void f1274(wasmcomponentldInstance*,U32);

void f1275(wasmcomponentldInstance*,U32);

void f1276(wasmcomponentldInstance*,U32);

void f1277(wasmcomponentldInstance*,U32);

void f1278(wasmcomponentldInstance*,U32,U32);

void f1279(wasmcomponentldInstance*,U32,U32);

void f1280(wasmcomponentldInstance*,U32,U32);

void f1281(wasmcomponentldInstance*,U32,U32);

void f1282(wasmcomponentldInstance*,U32,U32);

void f1283(wasmcomponentldInstance*,U32,U32);

void f1284(wasmcomponentldInstance*,U32,U32);

void f1285(wasmcomponentldInstance*,U32,U32,U64);

void f1286(wasmcomponentldInstance*,U32,U32);

void f1287(wasmcomponentldInstance*,U32,U32);

void f1288(wasmcomponentldInstance*,U32,U32);

void f1289(wasmcomponentldInstance*,U32,U32);

void f1290(wasmcomponentldInstance*,U32,U32);

void f1291(wasmcomponentldInstance*,U32,U32);

void f1292(wasmcomponentldInstance*,U32,U32);

void f1293(wasmcomponentldInstance*,U32,U32,U32,U32);

void f1294(wasmcomponentldInstance*,U32,U32);

void f1295(wasmcomponentldInstance*,U32,U32);

void f1296(wasmcomponentldInstance*,U32,U32);

void f1297(wasmcomponentldInstance*,U32,U32);

void f1298(wasmcomponentldInstance*,U32,U32);

void f1299(wasmcomponentldInstance*,U32,U32);

void f1300(wasmcomponentldInstance*,U32,U32);

void f1301(wasmcomponentldInstance*,U32,U32);

void f1302(wasmcomponentldInstance*,U32,U32);

void f1303(wasmcomponentldInstance*,U32,U32);

void f1304(wasmcomponentldInstance*,U32,U32);

void f1305(wasmcomponentldInstance*,U32,U32);

void f1306(wasmcomponentldInstance*,U32,U32);

void f1307(wasmcomponentldInstance*,U32,U32);

void f1308(wasmcomponentldInstance*,U32,U32);

void f1309(wasmcomponentldInstance*,U32,U32);

void f1310(wasmcomponentldInstance*,U32,U32);

void f1311(wasmcomponentldInstance*,U32,U32);

void f1312(wasmcomponentldInstance*,U32,U32);

void f1313(wasmcomponentldInstance*,U32,U32);

void f1314(wasmcomponentldInstance*,U32,U32);

void f1315(wasmcomponentldInstance*,U32,U32);

void f1316(wasmcomponentldInstance*,U32,U32);

void f1317(wasmcomponentldInstance*,U32,U32);

void f1318(wasmcomponentldInstance*,U32,U32);

void f1319(wasmcomponentldInstance*,U32,U32);

void f1320(wasmcomponentldInstance*,U32,U32);

void f1321(wasmcomponentldInstance*,U32,U32);

void f1322(wasmcomponentldInstance*,U32,U32);

void f1323(wasmcomponentldInstance*,U32,U32);

void f1324(wasmcomponentldInstance*,U32,U32);

void f1325(wasmcomponentldInstance*,U32,U32);

void f1326(wasmcomponentldInstance*,U32,U32);

void f1327(wasmcomponentldInstance*,U32,U32);

void f1328(wasmcomponentldInstance*,U32,U32);

void f1329(wasmcomponentldInstance*,U32,U32);

void f1330(wasmcomponentldInstance*,U32,U32);

void f1331(wasmcomponentldInstance*,U32,U32);

void f1332(wasmcomponentldInstance*,U32,U32);

void f1333(wasmcomponentldInstance*,U32,U32);

void f1334(wasmcomponentldInstance*,U32,U32);

void f1335(wasmcomponentldInstance*,U32,U32);

void f1336(wasmcomponentldInstance*,U32,U32);

void f1337(wasmcomponentldInstance*,U32,U32);

void f1338(wasmcomponentldInstance*,U32,U32);

void f1339(wasmcomponentldInstance*,U32,U32);

void f1340(wasmcomponentldInstance*,U32,U32);

void f1341(wasmcomponentldInstance*,U32,U32);

void f1342(wasmcomponentldInstance*,U32,U32);

void f1343(wasmcomponentldInstance*,U32,U32);

void f1344(wasmcomponentldInstance*,U32,U32);

void f1345(wasmcomponentldInstance*,U32,U32);

void f1346(wasmcomponentldInstance*,U32,U32);

void f1347(wasmcomponentldInstance*,U32,U32);

void f1348(wasmcomponentldInstance*,U32,U32);

void f1349(wasmcomponentldInstance*,U32,U32);

void f1350(wasmcomponentldInstance*,U32,U32);

void f1351(wasmcomponentldInstance*,U32,U32);

void f1352(wasmcomponentldInstance*,U32,U32);

void f1353(wasmcomponentldInstance*,U32,U32);

void f1354(wasmcomponentldInstance*,U32,U32);

void f1355(wasmcomponentldInstance*,U32,U32);

void f1356(wasmcomponentldInstance*,U32,U32);

void f1357(wasmcomponentldInstance*,U32,U32);

void f1358(wasmcomponentldInstance*,U32,U32);

void f1359(wasmcomponentldInstance*,U32,U32);

void f1360(wasmcomponentldInstance*,U32,U32);

void f1361(wasmcomponentldInstance*,U32,U32);

void f1362(wasmcomponentldInstance*,U32,U32);

void f1363(wasmcomponentldInstance*,U32,U32);

void f1364(wasmcomponentldInstance*,U32,U32);

void f1365(wasmcomponentldInstance*,U32,U32);

void f1366(wasmcomponentldInstance*,U32,U32);

void f1367(wasmcomponentldInstance*,U32,U32);

void f1368(wasmcomponentldInstance*,U32,U32);

void f1369(wasmcomponentldInstance*,U32,U32);

void f1370(wasmcomponentldInstance*,U32,U32);

void f1371(wasmcomponentldInstance*,U32,U32);

void f1372(wasmcomponentldInstance*,U32,U32);

void f1373(wasmcomponentldInstance*,U32,U32);

void f1374(wasmcomponentldInstance*,U32,U32);

void f1375(wasmcomponentldInstance*,U32,U32);

void f1376(wasmcomponentldInstance*,U32,U32);

void f1377(wasmcomponentldInstance*,U32,U32);

void f1378(wasmcomponentldInstance*,U32,U32);

void f1379(wasmcomponentldInstance*,U32,U32);

void f1380(wasmcomponentldInstance*,U32,U32);

void f1381(wasmcomponentldInstance*,U32,U32);

void f1382(wasmcomponentldInstance*,U32,U32);

void f1383(wasmcomponentldInstance*,U32,U32);

void f1384(wasmcomponentldInstance*,U32,U32);

void f1385(wasmcomponentldInstance*,U32,U32);

void f1386(wasmcomponentldInstance*,U32,U32);

void f1387(wasmcomponentldInstance*,U32,U32);

void f1388(wasmcomponentldInstance*,U32,U32);

void f1389(wasmcomponentldInstance*,U32,U32);

void f1390(wasmcomponentldInstance*,U32,U32);

void f1391(wasmcomponentldInstance*,U32,U32);

void f1392(wasmcomponentldInstance*,U32,U32);

void f1393(wasmcomponentldInstance*,U32,U32);

void f1394(wasmcomponentldInstance*,U32,U32);

void f1395(wasmcomponentldInstance*,U32,U32);

void f1396(wasmcomponentldInstance*,U32,U32);

void f1397(wasmcomponentldInstance*,U32,U32);

void f1398(wasmcomponentldInstance*,U32,U32);

void f1399(wasmcomponentldInstance*,U32,U32);

void f1400(wasmcomponentldInstance*,U32,U32);

void f1401(wasmcomponentldInstance*,U32,U32);

void f1402(wasmcomponentldInstance*,U32,U32);

void f1403(wasmcomponentldInstance*,U32,U32);

void f1404(wasmcomponentldInstance*,U32,U32);

void f1405(wasmcomponentldInstance*,U32,U32);

void f1406(wasmcomponentldInstance*,U32,U32);

void f1407(wasmcomponentldInstance*,U32,U32);

void f1408(wasmcomponentldInstance*,U32,U32);

void f1409(wasmcomponentldInstance*,U32,U32);

void f1410(wasmcomponentldInstance*,U32,U32);

void f1411(wasmcomponentldInstance*,U32,U32);

void f1412(wasmcomponentldInstance*,U32,U32);

void f1413(wasmcomponentldInstance*,U32,U32);

void f1414(wasmcomponentldInstance*,U32,U32);

void f1415(wasmcomponentldInstance*,U32,U32);

void f1416(wasmcomponentldInstance*,U32,U32);

void f1417(wasmcomponentldInstance*,U32,U32);

void f1418(wasmcomponentldInstance*,U32,U32);

void f1419(wasmcomponentldInstance*,U32,U32);

void f1420(wasmcomponentldInstance*,U32,U32);

void f1421(wasmcomponentldInstance*,U32,U32);

void f1422(wasmcomponentldInstance*,U32,U32);

void f1423(wasmcomponentldInstance*,U32,U32);

void f1424(wasmcomponentldInstance*,U32,U32);

void f1425(wasmcomponentldInstance*,U32,U32);

void f1426(wasmcomponentldInstance*,U32,U32);

void f1427(wasmcomponentldInstance*,U32,U32);

void f1428(wasmcomponentldInstance*,U32,U32);

void f1429(wasmcomponentldInstance*,U32,U32);

void f1430(wasmcomponentldInstance*,U32,U32);

void f1431(wasmcomponentldInstance*,U32,U32);

void f1432(wasmcomponentldInstance*,U32,U32);

void f1433(wasmcomponentldInstance*,U32,U32);

void f1434(wasmcomponentldInstance*,U32,U32);

void f1435(wasmcomponentldInstance*,U32,U32);

void f1436(wasmcomponentldInstance*,U32,U32);

void f1437(wasmcomponentldInstance*,U32,U32);

void f1438(wasmcomponentldInstance*,U32,U32);

void f1439(wasmcomponentldInstance*,U32,U32);

void f1440(wasmcomponentldInstance*,U32,U32);

void f1441(wasmcomponentldInstance*,U32,U32);

void f1442(wasmcomponentldInstance*,U32,U32);

void f1443(wasmcomponentldInstance*,U32,U32);

void f1444(wasmcomponentldInstance*,U32,U32);

void f1445(wasmcomponentldInstance*,U32,U32);

void f1446(wasmcomponentldInstance*,U32,U32);

void f1447(wasmcomponentldInstance*,U32,U32);

void f1448(wasmcomponentldInstance*,U32,U32);

void f1449(wasmcomponentldInstance*,U32,U32);

void f1450(wasmcomponentldInstance*,U32,U32);

void f1451(wasmcomponentldInstance*,U32,U32);

void f1452(wasmcomponentldInstance*,U32,U32);

void f1453(wasmcomponentldInstance*,U32,U32);

void f1454(wasmcomponentldInstance*,U32,U32);

void f1455(wasmcomponentldInstance*,U32,U32);

void f1456(wasmcomponentldInstance*,U32,U32);

void f1457(wasmcomponentldInstance*,U32,U32);

void f1458(wasmcomponentldInstance*,U32,U32);

void f1459(wasmcomponentldInstance*,U32,U32);

void f1460(wasmcomponentldInstance*,U32,U32);

void f1461(wasmcomponentldInstance*,U32,U32);

void f1462(wasmcomponentldInstance*,U32,U32);

void f1463(wasmcomponentldInstance*,U32,U32);

void f1464(wasmcomponentldInstance*,U32,U32);

void f1465(wasmcomponentldInstance*,U32,U32);

void f1466(wasmcomponentldInstance*,U32,U32);

void f1467(wasmcomponentldInstance*,U32,U32);

void f1468(wasmcomponentldInstance*,U32,U32);

void f1469(wasmcomponentldInstance*,U32,U32);

void f1470(wasmcomponentldInstance*,U32,U32);

void f1471(wasmcomponentldInstance*,U32,U32);

void f1472(wasmcomponentldInstance*,U32,U32);

void f1473(wasmcomponentldInstance*,U32,U32);

void f1474(wasmcomponentldInstance*,U32,U32);

void f1475(wasmcomponentldInstance*,U32,U32);

void f1476(wasmcomponentldInstance*,U32,U32);

void f1477(wasmcomponentldInstance*,U32,U32);

void f1478(wasmcomponentldInstance*,U32,U32);

void f1479(wasmcomponentldInstance*,U32,U32);

void f1480(wasmcomponentldInstance*,U32,U32);

void f1481(wasmcomponentldInstance*,U32,U32);

void f1482(wasmcomponentldInstance*,U32,U32);

void f1483(wasmcomponentldInstance*,U32,U32);

void f1484(wasmcomponentldInstance*,U32,U32);

void f1485(wasmcomponentldInstance*,U32,U32);

void f1486(wasmcomponentldInstance*,U32,U32);

void f1487(wasmcomponentldInstance*,U32,U32);

void f1488(wasmcomponentldInstance*,U32,U32);

void f1489(wasmcomponentldInstance*,U32,U32);

void f1490(wasmcomponentldInstance*,U32,U32);

void f1491(wasmcomponentldInstance*,U32,U32);

void f1492(wasmcomponentldInstance*,U32,U32);

void f1493(wasmcomponentldInstance*,U32,U32);

void f1494(wasmcomponentldInstance*,U32,U32);

void f1495(wasmcomponentldInstance*,U32,U32);

void f1496(wasmcomponentldInstance*,U32,U32);

void f1497(wasmcomponentldInstance*,U32,U32);

void f1498(wasmcomponentldInstance*,U32,U32);

void f1499(wasmcomponentldInstance*,U32,U32);

void f1500(wasmcomponentldInstance*,U32,U32);

void f1501(wasmcomponentldInstance*,U32,U32);

void f1502(wasmcomponentldInstance*,U32,U32);

void f1503(wasmcomponentldInstance*,U32,U32);

void f1504(wasmcomponentldInstance*,U32,U32);

void f1505(wasmcomponentldInstance*,U32,U32);

void f1506(wasmcomponentldInstance*,U32,U32);

void f1507(wasmcomponentldInstance*,U32,U32);

void f1508(wasmcomponentldInstance*,U32,U32);

void f1509(wasmcomponentldInstance*,U32,U32);

void f1510(wasmcomponentldInstance*,U32,U32);

void f1511(wasmcomponentldInstance*,U32,U32);

void f1512(wasmcomponentldInstance*,U32,U32);

void f1513(wasmcomponentldInstance*,U32,U32);

void f1514(wasmcomponentldInstance*,U32,U32);

void f1515(wasmcomponentldInstance*,U32,U32);

void f1516(wasmcomponentldInstance*,U32,U32);

void f1517(wasmcomponentldInstance*,U32,U32);

void f1518(wasmcomponentldInstance*,U32,U32);

void f1519(wasmcomponentldInstance*,U32,U32);

void f1520(wasmcomponentldInstance*,U32,U32);

void f1521(wasmcomponentldInstance*,U32,U32);

void f1522(wasmcomponentldInstance*,U32,U32);

void f1523(wasmcomponentldInstance*,U32,U32);

void f1524(wasmcomponentldInstance*,U32,U32);

void f1525(wasmcomponentldInstance*,U32,U32);

void f1526(wasmcomponentldInstance*,U32,U32);

void f1527(wasmcomponentldInstance*,U32,U32);

void f1528(wasmcomponentldInstance*,U32,U32);

void f1529(wasmcomponentldInstance*,U32,U32);

void f1530(wasmcomponentldInstance*,U32,U32);

void f1531(wasmcomponentldInstance*,U32,U32);

void f1532(wasmcomponentldInstance*,U32,U32);

void f1533(wasmcomponentldInstance*,U32,U32);

void f1534(wasmcomponentldInstance*,U32,U32);

void f1535(wasmcomponentldInstance*,U32,U32);

void f1536(wasmcomponentldInstance*,U32,U32);

void f1537(wasmcomponentldInstance*,U32,U32);

void f1538(wasmcomponentldInstance*,U32,U32);

void f1539(wasmcomponentldInstance*,U32,U32);

void f1540(wasmcomponentldInstance*,U32,U32);

void f1541(wasmcomponentldInstance*,U32,U32);

void f1542(wasmcomponentldInstance*,U32,U32);

void f1543(wasmcomponentldInstance*,U32,U32);

void f1544(wasmcomponentldInstance*,U32,U32);

void f1545(wasmcomponentldInstance*,U32,U32);

void f1546(wasmcomponentldInstance*,U32,U32);

void f1547(wasmcomponentldInstance*,U32,U32);

void f1548(wasmcomponentldInstance*,U32,U32);

void f1549(wasmcomponentldInstance*,U32,U32);

void f1550(wasmcomponentldInstance*,U32,U32);

void f1551(wasmcomponentldInstance*,U32,U32);

void f1552(wasmcomponentldInstance*,U32,U32);

void f1553(wasmcomponentldInstance*,U32,U32);

void f1554(wasmcomponentldInstance*,U32,U32);

void f1555(wasmcomponentldInstance*,U32,U32);

void f1556(wasmcomponentldInstance*,U32,U32);

void f1557(wasmcomponentldInstance*,U32,U32);

void f1558(wasmcomponentldInstance*,U32,U32);

void f1559(wasmcomponentldInstance*,U32,U32);

void f1560(wasmcomponentldInstance*,U32,U32);

void f1561(wasmcomponentldInstance*,U32,U32);

void f1562(wasmcomponentldInstance*,U32,U32);

void f1563(wasmcomponentldInstance*,U32,U32);

void f1564(wasmcomponentldInstance*,U32,U32);

void f1565(wasmcomponentldInstance*,U32,U32);

void f1566(wasmcomponentldInstance*,U32,U32);

void f1567(wasmcomponentldInstance*,U32,U32);

void f1568(wasmcomponentldInstance*,U32,U32);

void f1569(wasmcomponentldInstance*,U32,U32);

void f1570(wasmcomponentldInstance*,U32,U32);

void f1571(wasmcomponentldInstance*,U32,U32);

void f1572(wasmcomponentldInstance*,U32,U32);

void f1573(wasmcomponentldInstance*,U32,U32);

void f1574(wasmcomponentldInstance*,U32,U32);

void f1575(wasmcomponentldInstance*,U32,U32);

void f1576(wasmcomponentldInstance*,U32,U32);

void f1577(wasmcomponentldInstance*,U32,U32);

void f1578(wasmcomponentldInstance*,U32,U32);

void f1579(wasmcomponentldInstance*,U32,U32);

void f1580(wasmcomponentldInstance*,U32,U32);

void f1581(wasmcomponentldInstance*,U32,U32);

void f1582(wasmcomponentldInstance*,U32,U32);

void f1583(wasmcomponentldInstance*,U32,U32);

void f1584(wasmcomponentldInstance*,U32,U32);

void f1585(wasmcomponentldInstance*,U32,U32);

void f1586(wasmcomponentldInstance*,U32,U32);

void f1587(wasmcomponentldInstance*,U32,U32);

void f1588(wasmcomponentldInstance*,U32,U32);

void f1589(wasmcomponentldInstance*,U32,U32);

void f1590(wasmcomponentldInstance*,U32,U32);

void f1591(wasmcomponentldInstance*,U32,U32);

void f1592(wasmcomponentldInstance*,U32,U32);

void f1593(wasmcomponentldInstance*,U32,U32);

void f1594(wasmcomponentldInstance*,U32,U32);

void f1595(wasmcomponentldInstance*,U32,U32);

void f1596(wasmcomponentldInstance*,U32,U32);

void f1597(wasmcomponentldInstance*,U32,U32);

void f1598(wasmcomponentldInstance*,U32,U32);

void f1599(wasmcomponentldInstance*,U32,U32);

void f1600(wasmcomponentldInstance*,U32,U32);

void f1601(wasmcomponentldInstance*,U32,U32);

void f1602(wasmcomponentldInstance*,U32,U32);

void f1603(wasmcomponentldInstance*,U32,U32);

void f1604(wasmcomponentldInstance*,U32,U32);

void f1605(wasmcomponentldInstance*,U32,U32);

void f1606(wasmcomponentldInstance*,U32,U32);

void f1607(wasmcomponentldInstance*,U32,U32);

void f1608(wasmcomponentldInstance*,U32,U32);

void f1609(wasmcomponentldInstance*,U32,U32);

void f1610(wasmcomponentldInstance*,U32,U32);

void f1611(wasmcomponentldInstance*,U32,U32);

void f1612(wasmcomponentldInstance*,U32,U32);

void f1613(wasmcomponentldInstance*,U32,U32);

void f1614(wasmcomponentldInstance*,U32,U32);

void f1615(wasmcomponentldInstance*,U32,U32);

void f1616(wasmcomponentldInstance*,U32,U32);

void f1617(wasmcomponentldInstance*,U32,U32);

void f1618(wasmcomponentldInstance*,U32,U32);

void f1619(wasmcomponentldInstance*,U32,U32);

void f1620(wasmcomponentldInstance*,U32,U32);

void f1621(wasmcomponentldInstance*,U32,U32);

void f1622(wasmcomponentldInstance*,U32,U32);

void f1623(wasmcomponentldInstance*,U32,U32);

void f1624(wasmcomponentldInstance*,U32,U32);

void f1625(wasmcomponentldInstance*,U32,U32);

void f1626(wasmcomponentldInstance*,U32,U32);

void f1627(wasmcomponentldInstance*,U32,U32);

void f1628(wasmcomponentldInstance*,U32,U32);

void f1629(wasmcomponentldInstance*,U32,U32);

void f1630(wasmcomponentldInstance*,U32,U32);

void f1631(wasmcomponentldInstance*,U64,U32);

void f1632(wasmcomponentldInstance*,U32,U32);

void f1633(wasmcomponentldInstance*,U64,U32);

void f1634(wasmcomponentldInstance*,U32,U32);

void f1635(wasmcomponentldInstance*,U32,U32);

void f1636(wasmcomponentldInstance*,U32,U32);

void f1637(wasmcomponentldInstance*,U32,U32);

void f1638(wasmcomponentldInstance*,U32,U32);

void f1639(wasmcomponentldInstance*,U32,U32);

void f1640(wasmcomponentldInstance*,U32,U32);

void f1641(wasmcomponentldInstance*,U32,U32);

void f1642(wasmcomponentldInstance*,U32,U32);

void f1643(wasmcomponentldInstance*,U32,U32);

void f1644(wasmcomponentldInstance*,U32,U32);

void f1645(wasmcomponentldInstance*,U32,U32);

void f1646(wasmcomponentldInstance*,U32,U32);

void f1647(wasmcomponentldInstance*,U32,U32);

void f1648(wasmcomponentldInstance*,U32,U32);

void f1649(wasmcomponentldInstance*,U32,U32);

void f1650(wasmcomponentldInstance*,U32,U32);

void f1651(wasmcomponentldInstance*,U32,U32);

void f1652(wasmcomponentldInstance*,U32,U32);

void f1653(wasmcomponentldInstance*,U32,U32);

void f1654(wasmcomponentldInstance*,U32,U32);

void f1655(wasmcomponentldInstance*,U32,U32);

void f1656(wasmcomponentldInstance*,U32,U32);

void f1657(wasmcomponentldInstance*,U32,U32);

void f1658(wasmcomponentldInstance*,U32,U32);

void f1659(wasmcomponentldInstance*,U32,U32);

void f1660(wasmcomponentldInstance*,U32,U32);

void f1661(wasmcomponentldInstance*,U32,U32);

void f1662(wasmcomponentldInstance*,U32,U32);

void f1663(wasmcomponentldInstance*,U32,U32);

void f1664(wasmcomponentldInstance*,U32,U32);

void f1665(wasmcomponentldInstance*,U32,U32);

void f1666(wasmcomponentldInstance*,U32,U32);

void f1667(wasmcomponentldInstance*,U32,U32);

void f1668(wasmcomponentldInstance*,U32,U32);

void f1669(wasmcomponentldInstance*,U32,U32);

void f1670(wasmcomponentldInstance*,U32,U32);

void f1671(wasmcomponentldInstance*,U32,U32);

void f1672(wasmcomponentldInstance*,U32,U32);

void f1673(wasmcomponentldInstance*,U32,U32);

void f1674(wasmcomponentldInstance*,U32,U32);

void f1675(wasmcomponentldInstance*,U32,U32);

void f1676(wasmcomponentldInstance*,U32,U32);

void f1677(wasmcomponentldInstance*,U32,U32);

void f1678(wasmcomponentldInstance*,U32,U32);

void f1679(wasmcomponentldInstance*,U32,U32);

void f1680(wasmcomponentldInstance*,U32,U32);

void f1681(wasmcomponentldInstance*,U32,U32);

void f1682(wasmcomponentldInstance*,U32,U32);

void f1683(wasmcomponentldInstance*,U32,U32);

void f1684(wasmcomponentldInstance*,U32,U32);

void f1685(wasmcomponentldInstance*,U32,U32);

void f1686(wasmcomponentldInstance*,U32,U32);

void f1687(wasmcomponentldInstance*,U32,U32);

void f1688(wasmcomponentldInstance*,U32,U32);

void f1689(wasmcomponentldInstance*,U32,U32);

void f1690(wasmcomponentldInstance*,U32,U32);

void f1691(wasmcomponentldInstance*,U32,U32);

void f1692(wasmcomponentldInstance*,U32,U32);

void f1693(wasmcomponentldInstance*,U32,U32);

void f1694(wasmcomponentldInstance*,U32,U32);

void f1695(wasmcomponentldInstance*,U32,U32);

void f1696(wasmcomponentldInstance*,U32,U32);

void f1697(wasmcomponentldInstance*,U32,U32);

void f1698(wasmcomponentldInstance*,U32,U32);

void f1699(wasmcomponentldInstance*,U32,U32);

void f1700(wasmcomponentldInstance*,U32,U32);

void f1701(wasmcomponentldInstance*,U32,U32);

void f1702(wasmcomponentldInstance*,U32,U32);

void f1703(wasmcomponentldInstance*,U32,U32);

void f1704(wasmcomponentldInstance*,U32,U32);

void f1705(wasmcomponentldInstance*,U32,U32);

void f1706(wasmcomponentldInstance*,U32,U32);

void f1707(wasmcomponentldInstance*,U32,U32);

void f1708(wasmcomponentldInstance*,U32,U32);

void f1709(wasmcomponentldInstance*,U32,U32);

void f1710(wasmcomponentldInstance*,U32,U32);

void f1711(wasmcomponentldInstance*,U32,U32);

void f1712(wasmcomponentldInstance*,U32,U32);

void f1713(wasmcomponentldInstance*,U32,U32);

void f1714(wasmcomponentldInstance*,U32,U32);

void f1715(wasmcomponentldInstance*,U32,U32);

void f1716(wasmcomponentldInstance*,U32,U32);

void f1717(wasmcomponentldInstance*,U32,U32);

void f1718(wasmcomponentldInstance*,U32,U32);

void f1719(wasmcomponentldInstance*,U32,U32);

void f1720(wasmcomponentldInstance*,U32,U32);

void f1721(wasmcomponentldInstance*,U32,U32);

void f1722(wasmcomponentldInstance*,U32,U32);

void f1723(wasmcomponentldInstance*,U32,U32);

void f1724(wasmcomponentldInstance*,U32,U32);

void f1725(wasmcomponentldInstance*,U32,U32);

void f1726(wasmcomponentldInstance*,U32,U32);

void f1727(wasmcomponentldInstance*,U32,U32);

void f1728(wasmcomponentldInstance*,U32,U32);

void f1729(wasmcomponentldInstance*,U32,U32);

void f1730(wasmcomponentldInstance*,U32,U32);

void f1731(wasmcomponentldInstance*,U32,U32);

void f1732(wasmcomponentldInstance*,U32,U32);

void f1733(wasmcomponentldInstance*,U32,U32);

void f1734(wasmcomponentldInstance*,U32,U32);

void f1735(wasmcomponentldInstance*,U32,U32);

void f1736(wasmcomponentldInstance*,U32,U32);

void f1737(wasmcomponentldInstance*,U32,U32);

void f1738(wasmcomponentldInstance*,U32,U32);

void f1739(wasmcomponentldInstance*,U32,U32);

void f1740(wasmcomponentldInstance*,U32,U32);

void f1741(wasmcomponentldInstance*,U32,U32);

void f1742(wasmcomponentldInstance*,U32,U32);

void f1743(wasmcomponentldInstance*,U32,U32);

void f1744(wasmcomponentldInstance*,U32,U32);

void f1745(wasmcomponentldInstance*,U32,U32);

void f1746(wasmcomponentldInstance*,U32,U32);

void f1747(wasmcomponentldInstance*,U32,U32);

void f1748(wasmcomponentldInstance*,U32,U32);

void f1749(wasmcomponentldInstance*,U32,U32);

void f1750(wasmcomponentldInstance*,U32,U32);

void f1751(wasmcomponentldInstance*,U32,U32);

void f1752(wasmcomponentldInstance*,U32,U32);

void f1753(wasmcomponentldInstance*,U32,U32);

void f1754(wasmcomponentldInstance*,U32,U32);

void f1755(wasmcomponentldInstance*,U32,U32);

void f1756(wasmcomponentldInstance*,U32,U32);

void f1757(wasmcomponentldInstance*,U32,U32);

void f1758(wasmcomponentldInstance*,U32,U32);

void f1759(wasmcomponentldInstance*,U32,U32);

void f1760(wasmcomponentldInstance*,U32,U32);

void f1761(wasmcomponentldInstance*,U32,U32);

void f1762(wasmcomponentldInstance*,U32,U32);

void f1763(wasmcomponentldInstance*,U32,U32);

void f1764(wasmcomponentldInstance*,U32,U32);

void f1765(wasmcomponentldInstance*,U32,U32);

void f1766(wasmcomponentldInstance*,U32,U32);

void f1767(wasmcomponentldInstance*,U32,U32);

void f1768(wasmcomponentldInstance*,U32,U32);

void f1769(wasmcomponentldInstance*,U32,U32);

void f1770(wasmcomponentldInstance*,U32,U32);

void f1771(wasmcomponentldInstance*,U32,U32);

void f1772(wasmcomponentldInstance*,U32,U32);

void f1773(wasmcomponentldInstance*,U32);

void f1774(wasmcomponentldInstance*,U32);

void f1775(wasmcomponentldInstance*,U32);

void f1776(wasmcomponentldInstance*,U32);

void f1777(wasmcomponentldInstance*,U32);

void f1778(wasmcomponentldInstance*,U32);

void f1779(wasmcomponentldInstance*,U32);

void f1780(wasmcomponentldInstance*,U32);

void f1781(wasmcomponentldInstance*,U32);

void f1782(wasmcomponentldInstance*,U32);

void f1783(wasmcomponentldInstance*,U32);

void f1784(wasmcomponentldInstance*,U32);

void f1785(wasmcomponentldInstance*,U32);

void f1786(wasmcomponentldInstance*,U32);

void f1787(wasmcomponentldInstance*,U32);

void f1788(wasmcomponentldInstance*,U32);

void f1789(wasmcomponentldInstance*,U32);

void f1790(wasmcomponentldInstance*,U32);

void f1791(wasmcomponentldInstance*,U32);

void f1792(wasmcomponentldInstance*,U32);

void f1793(wasmcomponentldInstance*,U32);

void f1794(wasmcomponentldInstance*,U32);

void f1795(wasmcomponentldInstance*,U32);

void f1796(wasmcomponentldInstance*,U32);

void f1797(wasmcomponentldInstance*,U32);

void f1798(wasmcomponentldInstance*,U32);

void f1799(wasmcomponentldInstance*,U32);

void f1800(wasmcomponentldInstance*,U32);

void f1801(wasmcomponentldInstance*,U32);

void f1802(wasmcomponentldInstance*,U32);

void f1803(wasmcomponentldInstance*,U32);

void f1804(wasmcomponentldInstance*,U32);

void f1805(wasmcomponentldInstance*,U32);

void f1806(wasmcomponentldInstance*,U32);

void f1807(wasmcomponentldInstance*,U32);

void f1808(wasmcomponentldInstance*,U32);

void f1809(wasmcomponentldInstance*,U32);

void f1810(wasmcomponentldInstance*,U32);

void f1811(wasmcomponentldInstance*,U32);

void f1812(wasmcomponentldInstance*,U32);

void f1813(wasmcomponentldInstance*,U32);

void f1814(wasmcomponentldInstance*,U32);

void f1815(wasmcomponentldInstance*,U32);

void f1816(wasmcomponentldInstance*,U32);

void f1817(wasmcomponentldInstance*,U32);

void f1818(wasmcomponentldInstance*,U32);

void f1819(wasmcomponentldInstance*,U32);

void f1820(wasmcomponentldInstance*,U32);

void f1821(wasmcomponentldInstance*,U32);

void f1822(wasmcomponentldInstance*,U32);

void f1823(wasmcomponentldInstance*,U32);

void f1824(wasmcomponentldInstance*,U32);

void f1825(wasmcomponentldInstance*,U32);

void f1826(wasmcomponentldInstance*,U32);

void f1827(wasmcomponentldInstance*,U32);

void f1828(wasmcomponentldInstance*,U32);

void f1829(wasmcomponentldInstance*,U32);

void f1830(wasmcomponentldInstance*,U32);

void f1831(wasmcomponentldInstance*,U32);

void f1832(wasmcomponentldInstance*,U32);

void f1833(wasmcomponentldInstance*,U32);

void f1834(wasmcomponentldInstance*,U32);

void f1835(wasmcomponentldInstance*,U32);

void f1836(wasmcomponentldInstance*,U32);

void f1837(wasmcomponentldInstance*,U32);

void f1838(wasmcomponentldInstance*,U32);

void f1839(wasmcomponentldInstance*,U32);

void f1840(wasmcomponentldInstance*,U32);

void f1841(wasmcomponentldInstance*,U32);

void f1842(wasmcomponentldInstance*,U32);

void f1843(wasmcomponentldInstance*,U32);

void f1844(wasmcomponentldInstance*,U32);

void f1845(wasmcomponentldInstance*,U32);

void f1846(wasmcomponentldInstance*,U32);

void f1847(wasmcomponentldInstance*,U32);

void f1848(wasmcomponentldInstance*,U32);

void f1849(wasmcomponentldInstance*,U32);

void f1850(wasmcomponentldInstance*,U32);

void f1851(wasmcomponentldInstance*,U32);

void f1852(wasmcomponentldInstance*,U32);

void f1853(wasmcomponentldInstance*,U32);

void f1854(wasmcomponentldInstance*,U32);

void f1855(wasmcomponentldInstance*,U32);

void f1856(wasmcomponentldInstance*,U32);

void f1857(wasmcomponentldInstance*,U32);

void f1858(wasmcomponentldInstance*,U32);

void f1859(wasmcomponentldInstance*,U32);

void f1860(wasmcomponentldInstance*,U32);

void f1861(wasmcomponentldInstance*,U32);

void f1862(wasmcomponentldInstance*,U32);

void f1863(wasmcomponentldInstance*,U32);

void f1864(wasmcomponentldInstance*,U32);

void f1865(wasmcomponentldInstance*,U32);

void f1866(wasmcomponentldInstance*,U32);

void f1867(wasmcomponentldInstance*,U32);

void f1868(wasmcomponentldInstance*,U32);

void f1869(wasmcomponentldInstance*,U32);

void f1870(wasmcomponentldInstance*,U32);

void f1871(wasmcomponentldInstance*,U32);

void f1872(wasmcomponentldInstance*,U32);

void f1873(wasmcomponentldInstance*,U32);

void f1874(wasmcomponentldInstance*,U32);

void f1875(wasmcomponentldInstance*,U32);

void f1876(wasmcomponentldInstance*,U32);

void f1877(wasmcomponentldInstance*,U32);

void f1878(wasmcomponentldInstance*,U32);

void f1879(wasmcomponentldInstance*,U32);

void f1880(wasmcomponentldInstance*,U32);

void f1881(wasmcomponentldInstance*,U32);

void f1882(wasmcomponentldInstance*,U32);

void f1883(wasmcomponentldInstance*,U32);

void f1884(wasmcomponentldInstance*,U32);

void f1885(wasmcomponentldInstance*,U32);

void f1886(wasmcomponentldInstance*,U32);

void f1887(wasmcomponentldInstance*,U32);

void f1888(wasmcomponentldInstance*,U32);

void f1889(wasmcomponentldInstance*,U32);

void f1890(wasmcomponentldInstance*,U32);

void f1891(wasmcomponentldInstance*,U32);

void f1892(wasmcomponentldInstance*,U32);

void f1893(wasmcomponentldInstance*,U32);

void f1894(wasmcomponentldInstance*,U32);

void f1895(wasmcomponentldInstance*,U32);

void f1896(wasmcomponentldInstance*,U32);

void f1897(wasmcomponentldInstance*,U32);

void f1898(wasmcomponentldInstance*,U32);

void f1899(wasmcomponentldInstance*,U32);

void f1900(wasmcomponentldInstance*,U32);

void f1901(wasmcomponentldInstance*,U32);

void f1902(wasmcomponentldInstance*,U32);

void f1903(wasmcomponentldInstance*,U32);

void f1904(wasmcomponentldInstance*,U32);

void f1905(wasmcomponentldInstance*,U32);

void f1906(wasmcomponentldInstance*,U32);

void f1907(wasmcomponentldInstance*,U32);

void f1908(wasmcomponentldInstance*,U32);

void f1909(wasmcomponentldInstance*,U32);

void f1910(wasmcomponentldInstance*,U32);

void f1911(wasmcomponentldInstance*,U32);

void f1912(wasmcomponentldInstance*,U32);

void f1913(wasmcomponentldInstance*,U32);

void f1914(wasmcomponentldInstance*,U32);

void f1915(wasmcomponentldInstance*,U32);

void f1916(wasmcomponentldInstance*,U32);

void f1917(wasmcomponentldInstance*,U32);

void f1918(wasmcomponentldInstance*,U32);

void f1919(wasmcomponentldInstance*,U32);

void f1920(wasmcomponentldInstance*,U32);

void f1921(wasmcomponentldInstance*,U32);

void f1922(wasmcomponentldInstance*,U32);

void f1923(wasmcomponentldInstance*,U32);

void f1924(wasmcomponentldInstance*,U32);

void f1925(wasmcomponentldInstance*,U32);

void f1926(wasmcomponentldInstance*,U32);

void f1927(wasmcomponentldInstance*,U32);

void f1928(wasmcomponentldInstance*,U32);

void f1929(wasmcomponentldInstance*,U32);

void f1930(wasmcomponentldInstance*,U32);

void f1931(wasmcomponentldInstance*,U32);

void f1932(wasmcomponentldInstance*,U32);

void f1933(wasmcomponentldInstance*,U32);

void f1934(wasmcomponentldInstance*,U32);

void f1935(wasmcomponentldInstance*,U32);

void f1936(wasmcomponentldInstance*,U32);

void f1937(wasmcomponentldInstance*,U32);

void f1938(wasmcomponentldInstance*,U32);

void f1939(wasmcomponentldInstance*,U32);

void f1940(wasmcomponentldInstance*,U32);

void f1941(wasmcomponentldInstance*,U32);

void f1942(wasmcomponentldInstance*,U32);

void f1943(wasmcomponentldInstance*,U32);

void f1944(wasmcomponentldInstance*,U32);

void f1945(wasmcomponentldInstance*,U32);

void f1946(wasmcomponentldInstance*,U32);

void f1947(wasmcomponentldInstance*,U32);

void f1948(wasmcomponentldInstance*,U32);

void f1949(wasmcomponentldInstance*,U32);

void f1950(wasmcomponentldInstance*,U32);

void f1951(wasmcomponentldInstance*,U32);

void f1952(wasmcomponentldInstance*,U32);

void f1953(wasmcomponentldInstance*,U32);

void f1954(wasmcomponentldInstance*,U32);

void f1955(wasmcomponentldInstance*,U32);

void f1956(wasmcomponentldInstance*,U32);

void f1957(wasmcomponentldInstance*,U32);

void f1958(wasmcomponentldInstance*,U32);

void f1959(wasmcomponentldInstance*,U32);

void f1960(wasmcomponentldInstance*,U32);

void f1961(wasmcomponentldInstance*,U32);

void f1962(wasmcomponentldInstance*,U32);

void f1963(wasmcomponentldInstance*,U32);

void f1964(wasmcomponentldInstance*,U32);

void f1965(wasmcomponentldInstance*,U32);

void f1966(wasmcomponentldInstance*,U32);

void f1967(wasmcomponentldInstance*,U32);

void f1968(wasmcomponentldInstance*,U32);

void f1969(wasmcomponentldInstance*,U32);

void f1970(wasmcomponentldInstance*,U32);

void f1971(wasmcomponentldInstance*,U32,U32);

void f1972(wasmcomponentldInstance*,U32,U32);

void f1973(wasmcomponentldInstance*,U32,U32);

void f1974(wasmcomponentldInstance*,U32,U32);

void f1975(wasmcomponentldInstance*,U32,U32);

void f1976(wasmcomponentldInstance*,U32,U32);

void f1977(wasmcomponentldInstance*,U32);

void f1978(wasmcomponentldInstance*,U32);

void f1979(wasmcomponentldInstance*,U32);

void f1980(wasmcomponentldInstance*,U32);

void f1981(wasmcomponentldInstance*,U32);

void f1982(wasmcomponentldInstance*,U32);

void f1983(wasmcomponentldInstance*,U32);

void f1984(wasmcomponentldInstance*,U32);

void f1985(wasmcomponentldInstance*,U32);

void f1986(wasmcomponentldInstance*,U32);

void f1987(wasmcomponentldInstance*,U32);

void f1988(wasmcomponentldInstance*,U32);

void f1989(wasmcomponentldInstance*,U32);

void f1990(wasmcomponentldInstance*,U32);

void f1991(wasmcomponentldInstance*,U32);

void f1992(wasmcomponentldInstance*,U32);

void f1993(wasmcomponentldInstance*,U32);

void f1994(wasmcomponentldInstance*,U32);

void f1995(wasmcomponentldInstance*,U32);

void f1996(wasmcomponentldInstance*,U32);

void f1997(wasmcomponentldInstance*,U32,U32);

void f1998(wasmcomponentldInstance*,U32,U32);

void f1999(wasmcomponentldInstance*,U32,U32);

void f2000(wasmcomponentldInstance*,U32,U32);

void f2001(wasmcomponentldInstance*,U32,U32);

void f2002(wasmcomponentldInstance*,U32,U32);

void f2003(wasmcomponentldInstance*,U32,U32);

void f2004(wasmcomponentldInstance*,U32,U32);

void f2005(wasmcomponentldInstance*,U32,U32);

void f2006(wasmcomponentldInstance*,U32,U32);

void f2007(wasmcomponentldInstance*,U32,U32);

U32 f2008(wasmcomponentldInstance*,U32);

void f2009(wasmcomponentldInstance*,U32,U32);

void f2010(wasmcomponentldInstance*,U32,U32);

void f2011(wasmcomponentldInstance*,U32,U32);

void f2012(wasmcomponentldInstance*,U32,U32);

void f2013(wasmcomponentldInstance*,U32,U32);

void f2014(wasmcomponentldInstance*,U32,U32);

void f2015(wasmcomponentldInstance*,U32,U32);

void f2016(wasmcomponentldInstance*,U32,U32);

void f2017(wasmcomponentldInstance*,U32,U32);

void f2018(wasmcomponentldInstance*,U32,U32);

void f2019(wasmcomponentldInstance*,U32,U32);

void f2020(wasmcomponentldInstance*,U32,U32);

void f2021(wasmcomponentldInstance*,U32,U32);

void f2022(wasmcomponentldInstance*,U32,U32);

void f2023(wasmcomponentldInstance*,U32,U32);

void f2024(wasmcomponentldInstance*,U32,U32);

void f2025(wasmcomponentldInstance*,U32,U32);

void f2026(wasmcomponentldInstance*,U32,U32);

void f2027(wasmcomponentldInstance*,U32,U32);

void f2028(wasmcomponentldInstance*,U32,U32);

void f2029(wasmcomponentldInstance*,U32,U32);

void f2030(wasmcomponentldInstance*,U32,U32);

void f2031(wasmcomponentldInstance*,U32,U32);

void f2032(wasmcomponentldInstance*,U32,U32);

void f2033(wasmcomponentldInstance*,U32,U32);

void f2034(wasmcomponentldInstance*,U32,U32);

void f2035(wasmcomponentldInstance*,U32,U32);

void f2036(wasmcomponentldInstance*,U32,U32);

void f2037(wasmcomponentldInstance*,U32,U32);

void f2038(wasmcomponentldInstance*,U32,U32);

void f2039(wasmcomponentldInstance*,U32,U32);

void f2040(wasmcomponentldInstance*,U32,U32);

void f2041(wasmcomponentldInstance*,U32,U32);

void f2042(wasmcomponentldInstance*,U32,U32);

void f2043(wasmcomponentldInstance*,U32,U32);

void f2044(wasmcomponentldInstance*,U32,U32);

void f2045(wasmcomponentldInstance*,U32,U32);

void f2046(wasmcomponentldInstance*,U32,U32);

void f2047(wasmcomponentldInstance*,U32,U32);

void f2048(wasmcomponentldInstance*,U32,U32);

void f2049(wasmcomponentldInstance*,U32,U32);

void f2050(wasmcomponentldInstance*,U32,U32);

void f2051(wasmcomponentldInstance*,U32,U32);

void f2052(wasmcomponentldInstance*,U32,U32);

void f2053(wasmcomponentldInstance*,U32,U32);

void f2054(wasmcomponentldInstance*,U32,U32);

void f2055(wasmcomponentldInstance*,U32,U32);

void f2056(wasmcomponentldInstance*,U32,U32);

void f2057(wasmcomponentldInstance*,U32,U32);

void f2058(wasmcomponentldInstance*,U32,U32);

void f2059(wasmcomponentldInstance*,U32,U32);

void f2060(wasmcomponentldInstance*,U32,U32);

void f2061(wasmcomponentldInstance*,U32,U32);

void f2062(wasmcomponentldInstance*,U32,U32);

void f2063(wasmcomponentldInstance*,U32,U32);

void f2064(wasmcomponentldInstance*,U32,U32);

void f2065(wasmcomponentldInstance*,U32,U32);

void f2066(wasmcomponentldInstance*,U32,U32);

void f2067(wasmcomponentldInstance*,U32,U32);

void f2068(wasmcomponentldInstance*,U32,U32);

void f2069(wasmcomponentldInstance*,U32,U32);

void f2070(wasmcomponentldInstance*,U32,U32);

void f2071(wasmcomponentldInstance*,U32,U32);

void f2072(wasmcomponentldInstance*,U32,U32);

void f2073(wasmcomponentldInstance*,U32,U32);

U32 f2074(wasmcomponentldInstance*,U32,U32);

U32 f2075(wasmcomponentldInstance*,U32,U32);

U32 f2076(wasmcomponentldInstance*,U32,U32);

void f2077(wasmcomponentldInstance*,U32,U32,U32);

void f2078(wasmcomponentldInstance*,U32);

U64 f2079(wasmcomponentldInstance*,U32,U32,U32);

void f2080(wasmcomponentldInstance*,U32,U32,U32);

U64 f2081(wasmcomponentldInstance*,U32,U32);

U64 f2082(wasmcomponentldInstance*,U32,U32);

U64 f2083(wasmcomponentldInstance*,U32,U32);

U64 f2084(wasmcomponentldInstance*,U32,U32);

U32 f2085(wasmcomponentldInstance*,U32,U32);

void f2086(wasmcomponentldInstance*,U32,U32);

void f2087(wasmcomponentldInstance*,U32,U32);

void f2088(wasmcomponentldInstance*,U32,U32);

void f2089(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2090(wasmcomponentldInstance*,U32,U32);

void f2091(wasmcomponentldInstance*,U32,U32);

void f2092(wasmcomponentldInstance*,U32,U32);

void f2093(wasmcomponentldInstance*,U32,U32);

void f2094(wasmcomponentldInstance*,U32,U32);

void f2095(wasmcomponentldInstance*,U32,U32,U32);

U32 f2096(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2097(wasmcomponentldInstance*,U32,U32,U32);

U32 f2098(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2099(wasmcomponentldInstance*,U32,U32,U32);

U32 f2100(wasmcomponentldInstance*,U32,U32);

void f2101(wasmcomponentldInstance*,U32,U32);

void f2102(wasmcomponentldInstance*,U32,U32);

void f2103(wasmcomponentldInstance*,U32,U32);

void f2104(wasmcomponentldInstance*,U32,U32);

void f2105(wasmcomponentldInstance*,U32,U32);

void f2106(wasmcomponentldInstance*,U32);

void f2107(wasmcomponentldInstance*,U32);

U32 f2108(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2109(wasmcomponentldInstance*,U32,U32);

void f2110(wasmcomponentldInstance*,U32,U32);

void f2111(wasmcomponentldInstance*,U32,U32,U32);

void f2112(wasmcomponentldInstance*,U32,U32);

void f2113(wasmcomponentldInstance*,U32,U32);

void f2114(wasmcomponentldInstance*,U32,U32);

void f2115(wasmcomponentldInstance*,U32,U32);

void f2116(wasmcomponentldInstance*,U32,U32,U32);

void f2117(wasmcomponentldInstance*,U32,U32);

void f2118(wasmcomponentldInstance*,U32,U32);

void f2119(wasmcomponentldInstance*,U32,U32);

void f2120(wasmcomponentldInstance*,U32,U32);

void f2121(wasmcomponentldInstance*,U32,U32);

void f2122(wasmcomponentldInstance*,U32,U32);

void f2123(wasmcomponentldInstance*,U32,U32);

void f2124(wasmcomponentldInstance*,U32,U32);

void f2125(wasmcomponentldInstance*,U32,U32);

void f2126(wasmcomponentldInstance*,U32,U32);

void f2127(wasmcomponentldInstance*,U32,U32);

void f2128(wasmcomponentldInstance*,U32,U32);

void f2129(wasmcomponentldInstance*,U32,U32);

void f2130(wasmcomponentldInstance*,U32,U32);

void f2131(wasmcomponentldInstance*,U32,U32);

void f2132(wasmcomponentldInstance*,U32,U32);

void f2133(wasmcomponentldInstance*,U32,U32);

U32 f2134(wasmcomponentldInstance*,U32,U32,U32);

void f2135(wasmcomponentldInstance*,U32,U32);

void f2136(wasmcomponentldInstance*,U32,U32,U32);

void f2137(wasmcomponentldInstance*,U32,U32);

void f2138(wasmcomponentldInstance*,U32,U32,U32);

void f2139(wasmcomponentldInstance*,U32,U32);

void f2140(wasmcomponentldInstance*,U32,U32);

void f2141(wasmcomponentldInstance*,U32,U32);

void f2142(wasmcomponentldInstance*,U32,U32);

void f2143(wasmcomponentldInstance*,U32,U32);

void f2144(wasmcomponentldInstance*,U32,U32);

void f2145(wasmcomponentldInstance*,U32,U32);

void f2146(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2147(wasmcomponentldInstance*,U32,U32,U32);

U32 f2148(wasmcomponentldInstance*,U32,U32,U32);

void f2149(wasmcomponentldInstance*,U32,U32);

void f2150(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2151(wasmcomponentldInstance*,U32,U32,U32);

U32 f2152(wasmcomponentldInstance*,U32,U32);

void f2153(wasmcomponentldInstance*,U32);

void f2154(wasmcomponentldInstance*,U32);

void f2155(wasmcomponentldInstance*,U32);

void f2156(wasmcomponentldInstance*,U32);

void f2157(wasmcomponentldInstance*,U32);

void f2158(wasmcomponentldInstance*,U32);

void f2159(wasmcomponentldInstance*,U32);

void f2160(wasmcomponentldInstance*,U32);

U32 f2161(wasmcomponentldInstance*,U32,U32);

void f2162(wasmcomponentldInstance*,U32);

void f2163(wasmcomponentldInstance*,U32);

void f2164(wasmcomponentldInstance*,U32);

void f2165(wasmcomponentldInstance*,U32);

void f2166(wasmcomponentldInstance*,U32,U32);

void f2167(wasmcomponentldInstance*,U32,U32);

void f2168(wasmcomponentldInstance*,U32,U32);

void f2169(wasmcomponentldInstance*,U32,U32);

void f2170(wasmcomponentldInstance*,U32,U32);

void f2171(wasmcomponentldInstance*,U32,U32);

void f2172(wasmcomponentldInstance*,U32,U32);

void f2173(wasmcomponentldInstance*,U32,U32);

void f2174(wasmcomponentldInstance*,U32,U32);

void f2175(wasmcomponentldInstance*,U32,U32);

void f2176(wasmcomponentldInstance*,U32,U32);

void f2177(wasmcomponentldInstance*,U32,U32);

void f2178(wasmcomponentldInstance*,U32,U32);

void f2179(wasmcomponentldInstance*,U32,U32);

void f2180(wasmcomponentldInstance*,U32,U32);

void f2181(wasmcomponentldInstance*,U32,U32);

void f2182(wasmcomponentldInstance*,U32,U32,U32);

void f2183(wasmcomponentldInstance*,U32,U32,U32);

void f2184(wasmcomponentldInstance*,U32,U32);

void f2185(wasmcomponentldInstance*,U32,U32);

void f2186(wasmcomponentldInstance*,U32);

void f2187(wasmcomponentldInstance*,U32,U32);

void f2188(wasmcomponentldInstance*,U32,U32);

void f2189(wasmcomponentldInstance*,U32,U32);

void f2190(wasmcomponentldInstance*,U32);

U32 f2191(wasmcomponentldInstance*,U32,U32);

void f2192(wasmcomponentldInstance*,U32,U32);

void f2193(wasmcomponentldInstance*,U32,U32);

void f2194(wasmcomponentldInstance*,U32,U32);

void f2195(wasmcomponentldInstance*,U32,U32);

void f2196(wasmcomponentldInstance*,U32,U32);

void f2197(wasmcomponentldInstance*,U32,U32);

U32 f2198(wasmcomponentldInstance*,U32,U32,U32);

void f2199(wasmcomponentldInstance*,U32,U32);

void f2200(wasmcomponentldInstance*,U32,U32,U32);

void f2201(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2202(wasmcomponentldInstance*,U32,U32,U32);

U32 f2203(wasmcomponentldInstance*,U32,U32);

U32 f2204(wasmcomponentldInstance*,U32,U32);

U32 f2205(wasmcomponentldInstance*,U32,U32);

U32 f2206(wasmcomponentldInstance*,U32,U32);

U32 f2207(wasmcomponentldInstance*,U32,U32);

U32 f2208(wasmcomponentldInstance*,U32,U32);

U32 f2209(wasmcomponentldInstance*,U32,U32,U32);

U32 f2210(wasmcomponentldInstance*,U32,U32);

U32 f2211(wasmcomponentldInstance*,U32,U32);

U32 f2212(wasmcomponentldInstance*,U32,U32);

U32 f2213(wasmcomponentldInstance*,U32,U32);

U32 f2214(wasmcomponentldInstance*,U32,U32);

U32 f2215(wasmcomponentldInstance*,U32,U32);

U32 f2216(wasmcomponentldInstance*,U32,U32);

U32 f2217(wasmcomponentldInstance*,U32,U32);

void f2218(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2219(wasmcomponentldInstance*,U32,U32,U32);

void f2220(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2221(wasmcomponentldInstance*,U32,U32,U32);

void f2222(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2223(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2224(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2225(wasmcomponentldInstance*,U32,U32,U32);

void f2226(wasmcomponentldInstance*,U32);

void f2227(wasmcomponentldInstance*,U32);

void f2228(wasmcomponentldInstance*,U32);

void f2229(wasmcomponentldInstance*,U32);

void f2230(wasmcomponentldInstance*,U32);

void f2231(wasmcomponentldInstance*,U32);

void f2232(wasmcomponentldInstance*,U32);

void f2233(wasmcomponentldInstance*,U32);

void f2234(wasmcomponentldInstance*,U32);

void f2235(wasmcomponentldInstance*,U32);

void f2236(wasmcomponentldInstance*,U32);

void f2237(wasmcomponentldInstance*,U32);

void f2238(wasmcomponentldInstance*,U32);

void f2239(wasmcomponentldInstance*,U32);

void f2240(wasmcomponentldInstance*,U32);

void f2241(wasmcomponentldInstance*,U32);

void f2242(wasmcomponentldInstance*,U32,U32,U32);

void f2243(wasmcomponentldInstance*,U32,U32,U32);

void f2244(wasmcomponentldInstance*,U32);

void f2245(wasmcomponentldInstance*,U32);

void f2246(wasmcomponentldInstance*,U32);

void f2247(wasmcomponentldInstance*,U32);

void f2248(wasmcomponentldInstance*,U32);

void f2249(wasmcomponentldInstance*,U32);

void f2250(wasmcomponentldInstance*,U32);

void f2251(wasmcomponentldInstance*,U32);

void f2252(wasmcomponentldInstance*,U32);

void f2253(wasmcomponentldInstance*,U32);

void f2254(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2255(wasmcomponentldInstance*,U32);

void f2256(wasmcomponentldInstance*,U32,U32,U32);

void f2257(wasmcomponentldInstance*,U32,U32);

void f2258(wasmcomponentldInstance*,U32,U32);

void f2259(wasmcomponentldInstance*,U32,U32);

void f2260(wasmcomponentldInstance*,U32,U32);

void f2261(wasmcomponentldInstance*,U32,U32);

void f2262(wasmcomponentldInstance*,U32,U32);

void f2263(wasmcomponentldInstance*,U32,U32);

void f2264(wasmcomponentldInstance*,U32,U32);

void f2265(wasmcomponentldInstance*,U32,U32);

void f2266(wasmcomponentldInstance*,U32,U32);

void f2267(wasmcomponentldInstance*,U32,U32);

void f2268(wasmcomponentldInstance*,U32);

void f2269(wasmcomponentldInstance*,U32,U32,U32);

U32 f2270(wasmcomponentldInstance*,U32,U32);

U32 f2271(wasmcomponentldInstance*,U32,U32);

U32 f2272(wasmcomponentldInstance*,U32,U32);

U32 f2273(wasmcomponentldInstance*,U32,U32);

U32 f2274(wasmcomponentldInstance*,U32,U32);

U32 f2275(wasmcomponentldInstance*,U32,U32);

U32 f2276(wasmcomponentldInstance*,U32,U32);

U32 f2277(wasmcomponentldInstance*,U32,U32);

U32 f2278(wasmcomponentldInstance*,U32,U32);

U32 f2279(wasmcomponentldInstance*,U32,U32);

U32 f2280(wasmcomponentldInstance*,U32,U32);

void f2281(wasmcomponentldInstance*,U32,U32);

void f2282(wasmcomponentldInstance*,U32,U32);

void f2283(wasmcomponentldInstance*,U32,U32);

void f2284(wasmcomponentldInstance*,U32,U32);

void f2285(wasmcomponentldInstance*,U32,U32);

void f2286(wasmcomponentldInstance*,U32,U32);

void f2287(wasmcomponentldInstance*,U32);

void f2288(wasmcomponentldInstance*,U32);

void f2289(wasmcomponentldInstance*,U32);

void f2290(wasmcomponentldInstance*,U32);

void f2291(wasmcomponentldInstance*,U32);

void f2292(wasmcomponentldInstance*,U32);

void f2293(wasmcomponentldInstance*,U32);

void f2294(wasmcomponentldInstance*,U32);

void f2295(wasmcomponentldInstance*,U32);

void f2296(wasmcomponentldInstance*,U32);

U32 f2297(wasmcomponentldInstance*,U32,U32);

void f2298(wasmcomponentldInstance*,U32,U32);

void f2299(wasmcomponentldInstance*,U32,U32,U32);

void f2300(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f2301(wasmcomponentldInstance*,U32,U32,U32);

void f2302(wasmcomponentldInstance*,U32,U32);

U32 f2303(wasmcomponentldInstance*,U32);

void f2304(wasmcomponentldInstance*,U32,U32);

void f2305(wasmcomponentldInstance*,U32,U32);

void f2306(wasmcomponentldInstance*,U32,U32,U32);

void f2307(wasmcomponentldInstance*,U32,U32);

void f2308(wasmcomponentldInstance*,U32,U32);

void f2309(wasmcomponentldInstance*,U32,U32);

U32 f2310(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2311(wasmcomponentldInstance*,U32,U32);

U32 f2312(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2313(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2314(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2315(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2316(wasmcomponentldInstance*,U32,U32,U32);

U32 f2317(wasmcomponentldInstance*,U32,U32,U32);

U32 f2318(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2319(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2320(wasmcomponentldInstance*,U32,U32);

U32 f2321(wasmcomponentldInstance*,U32);

U32 f2322(wasmcomponentldInstance*,U32);

void f2323(wasmcomponentldInstance*,U32);

void f2324(wasmcomponentldInstance*,U32,U32);

void f2325(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f2326(wasmcomponentldInstance*,U32,U32);

U32 f2327(wasmcomponentldInstance*,U32,U32);

U32 f2328(wasmcomponentldInstance*,U32,U32,U32);

void f2329(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2330(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2331(wasmcomponentldInstance*,U32,U32);

void f2332(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2333(wasmcomponentldInstance*,U32,U32);

void f2334(wasmcomponentldInstance*,U32,U32,U32);

void f2335(wasmcomponentldInstance*,U32,U32,U32);

U32 f2336(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2337(wasmcomponentldInstance*,U32,U32);

void f2338(wasmcomponentldInstance*,U32,U32);

void f2339(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2340(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2341(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2342(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2343(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2344(wasmcomponentldInstance*,U32,U32);

void f2345(wasmcomponentldInstance*,U32,U32);

void f2346(wasmcomponentldInstance*,U32,U32);

void f2347(wasmcomponentldInstance*,U32,U32,U32);

void f2348(wasmcomponentldInstance*,U32,U32,U32);

void f2349(wasmcomponentldInstance*,U32,U32,U32);

void f2350(wasmcomponentldInstance*,U32,U32,U32);

U32 f2351(wasmcomponentldInstance*,U32,U32);

void f2352(wasmcomponentldInstance*,U32);

void f2353(wasmcomponentldInstance*,U32);

void f2354(wasmcomponentldInstance*,U32,U32);

void f2355(wasmcomponentldInstance*,U32,U32);

void f2356(wasmcomponentldInstance*,U32,U32);

void f2357(wasmcomponentldInstance*,U32,U32);

void f2358(wasmcomponentldInstance*,U32,U32);

void f2359(wasmcomponentldInstance*,U32,U32);

void f2360(wasmcomponentldInstance*,U32,U32);

void f2361(wasmcomponentldInstance*,U32,U32);

void f2362(wasmcomponentldInstance*,U32,U32);

void f2363(wasmcomponentldInstance*,U32,U32);

void f2364(wasmcomponentldInstance*,U32,U32);

void f2365(wasmcomponentldInstance*,U32,U32);

void f2366(wasmcomponentldInstance*,U32,U32);

void f2367(wasmcomponentldInstance*,U32,U32);

void f2368(wasmcomponentldInstance*,U32,U32);

void f2369(wasmcomponentldInstance*,U32,U32);

void f2370(wasmcomponentldInstance*,U32,U32);

void f2371(wasmcomponentldInstance*,U32,U32);

void f2372(wasmcomponentldInstance*,U32,U32);

void f2373(wasmcomponentldInstance*,U32,U32);

void f2374(wasmcomponentldInstance*,U32,U32,U32);

void f2375(wasmcomponentldInstance*,U32,U32);

void f2376(wasmcomponentldInstance*,U32,U32);

void f2377(wasmcomponentldInstance*,U32,U32);

void f2378(wasmcomponentldInstance*,U32,U32);

void f2379(wasmcomponentldInstance*,U32,U32,U32);

void f2380(wasmcomponentldInstance*,U32,U32);

void f2381(wasmcomponentldInstance*,U32,U32);

void f2382(wasmcomponentldInstance*,U32,U32);

void f2383(wasmcomponentldInstance*,U32,U32);

void f2384(wasmcomponentldInstance*,U32,U32);

void f2385(wasmcomponentldInstance*,U32,U32);

void f2386(wasmcomponentldInstance*,U32,U32);

void f2387(wasmcomponentldInstance*,U32,U32);

void f2388(wasmcomponentldInstance*,U32,U32);

void f2389(wasmcomponentldInstance*,U32,U32);

void f2390(wasmcomponentldInstance*,U32,U32);

void f2391(wasmcomponentldInstance*,U32,U32);

void f2392(wasmcomponentldInstance*,U32,U32);

void f2393(wasmcomponentldInstance*,U32,U32);

void f2394(wasmcomponentldInstance*,U32,U32);

void f2395(wasmcomponentldInstance*,U32,U32);

void f2396(wasmcomponentldInstance*,U32,U32);

void f2397(wasmcomponentldInstance*,U32,U32);

void f2398(wasmcomponentldInstance*,U32,U32);

void f2399(wasmcomponentldInstance*,U32,U32);

void f2400(wasmcomponentldInstance*,U32,U32);

void f2401(wasmcomponentldInstance*,U32,U32);

void f2402(wasmcomponentldInstance*,U32,U32);

void f2403(wasmcomponentldInstance*,U32,U32);

void f2404(wasmcomponentldInstance*,U32,U32);

void f2405(wasmcomponentldInstance*,U32);

void f2406(wasmcomponentldInstance*,U32);

U32 f2407(wasmcomponentldInstance*,U32,U32,U32);

void f2408(wasmcomponentldInstance*,U32);

void f2409(wasmcomponentldInstance*,U32,U32,U32);

void f2410(wasmcomponentldInstance*,U32,U32);

void f2411(wasmcomponentldInstance*,U32,U32);

void f2412(wasmcomponentldInstance*,U32,U32);

U32 f2413(wasmcomponentldInstance*,U32,U32);

U32 f2414(wasmcomponentldInstance*,U32,U32,U32);

void f2415(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2416(wasmcomponentldInstance*,U32,U32,U32);

U32 f2417(wasmcomponentldInstance*,U32,U32,U32);

U32 f2418(wasmcomponentldInstance*,U32,U32);

U32 f2419(wasmcomponentldInstance*,U32,U32);

U32 f2420(wasmcomponentldInstance*,U32,U32);

U32 f2421(wasmcomponentldInstance*,U32,U32,U32);

void f2422(wasmcomponentldInstance*,U32);

void f2423(wasmcomponentldInstance*,U32,U32,U32);

void f2424(wasmcomponentldInstance*,U32,U32,U32);

void f2425(wasmcomponentldInstance*,U32,U32);

void f2426(wasmcomponentldInstance*,U32,U32);

void f2427(wasmcomponentldInstance*,U32,U32);

void f2428(wasmcomponentldInstance*,U32);

void f2429(wasmcomponentldInstance*,U32);

void f2430(wasmcomponentldInstance*,U32);

void f2431(wasmcomponentldInstance*,U32);

void f2432(wasmcomponentldInstance*,U32,U32);

void f2433(wasmcomponentldInstance*,U32,U32);

void f2434(wasmcomponentldInstance*,U32,U32);

void f2435(wasmcomponentldInstance*,U32,U32);

void f2436(wasmcomponentldInstance*,U32,U32);

void f2437(wasmcomponentldInstance*,U32,U32);

void f2438(wasmcomponentldInstance*,U32,U32);

void f2439(wasmcomponentldInstance*,U32);

void f2440(wasmcomponentldInstance*,U32,U32,U32);

void f2441(wasmcomponentldInstance*,U32,U32);

void f2442(wasmcomponentldInstance*,U32,U32,U32);

void f2443(wasmcomponentldInstance*,U32,U32);

void f2444(wasmcomponentldInstance*,U32,U32);

void f2445(wasmcomponentldInstance*,U32,U32,U32);

void f2446(wasmcomponentldInstance*,U32,U32);

void f2447(wasmcomponentldInstance*,U32,U32,U32);

void f2448(wasmcomponentldInstance*,U32,U32);

void f2449(wasmcomponentldInstance*,U32,U32);

void f2450(wasmcomponentldInstance*,U32,U32);

void f2451(wasmcomponentldInstance*,U32,U32,U32);

void f2452(wasmcomponentldInstance*,U32,U32);

void f2453(wasmcomponentldInstance*,U32,U32);

void f2454(wasmcomponentldInstance*,U32,U32);

void f2455(wasmcomponentldInstance*,U32,U32);

void f2456(wasmcomponentldInstance*,U32,U32);

void f2457(wasmcomponentldInstance*,U32,U32);

void f2458(wasmcomponentldInstance*,U32,U32);

void f2459(wasmcomponentldInstance*,U32,U32);

void f2460(wasmcomponentldInstance*,U32,U32);

void f2461(wasmcomponentldInstance*,U32,U32);

void f2462(wasmcomponentldInstance*,U32,U32);

void f2463(wasmcomponentldInstance*,U32,U32);

void f2464(wasmcomponentldInstance*,U32,U32);

void f2465(wasmcomponentldInstance*,U32,U32);

void f2466(wasmcomponentldInstance*,U32,U32);

void f2467(wasmcomponentldInstance*,U32,U32);

void f2468(wasmcomponentldInstance*,U32,U32);

void f2469(wasmcomponentldInstance*,U32,U32);

void f2470(wasmcomponentldInstance*,U32,U32);

void f2471(wasmcomponentldInstance*,U32,U32);

void f2472(wasmcomponentldInstance*,U32,U32);

void f2473(wasmcomponentldInstance*,U32,U32);

void f2474(wasmcomponentldInstance*,U32,U32);

void f2475(wasmcomponentldInstance*,U32,U32);

void f2476(wasmcomponentldInstance*,U32,U32);

void f2477(wasmcomponentldInstance*,U32,U32);

void f2478(wasmcomponentldInstance*,U32,U32);

void f2479(wasmcomponentldInstance*,U32,U32);

void f2480(wasmcomponentldInstance*,U32,U32);

void f2481(wasmcomponentldInstance*,U32,U32);

void f2482(wasmcomponentldInstance*,U32,U32);

void f2483(wasmcomponentldInstance*,U32,U32);

void f2484(wasmcomponentldInstance*,U32,U32);

void f2485(wasmcomponentldInstance*,U32,U32);

void f2486(wasmcomponentldInstance*,U32,U32);

void f2487(wasmcomponentldInstance*,U32,U32);

void f2488(wasmcomponentldInstance*,U32,U32);

void f2489(wasmcomponentldInstance*,U32,U32);

void f2490(wasmcomponentldInstance*,U32,U32);

void f2491(wasmcomponentldInstance*,U32,U32);

void f2492(wasmcomponentldInstance*,U32,U32);

void f2493(wasmcomponentldInstance*,U32,U32);

void f2494(wasmcomponentldInstance*,U32,U32);

U32 f2495(wasmcomponentldInstance*,U32);

void f2496(wasmcomponentldInstance*,U32,U32,U32);

void f2497(wasmcomponentldInstance*,U32,U32,U32);

void f2498(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2499(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2500(wasmcomponentldInstance*,U32,U32,U32);

void f2501(wasmcomponentldInstance*,U32,U32);

void f2502(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2503(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2504(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2505(wasmcomponentldInstance*,U32,U32,U32);

void f2506(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f2507(wasmcomponentldInstance*,U32,U32);

void f2508(wasmcomponentldInstance*,U32,U32);

void f2509(wasmcomponentldInstance*,U32,U32,U32);

void f2510(wasmcomponentldInstance*,U32,U32);

void f2511(wasmcomponentldInstance*,U32,U32);

void f2512(wasmcomponentldInstance*,U32,U32);

void f2513(wasmcomponentldInstance*,U32,U32);

void f2514(wasmcomponentldInstance*,U32,U32);

void f2515(wasmcomponentldInstance*,U32,U32);

void f2516(wasmcomponentldInstance*,U32,U32);

void f2517(wasmcomponentldInstance*,U32,U32);

void f2518(wasmcomponentldInstance*,U32,U32);

void f2519(wasmcomponentldInstance*,U32,U32);

void f2520(wasmcomponentldInstance*,U32,U32);

void f2521(wasmcomponentldInstance*,U32,U32);

void f2522(wasmcomponentldInstance*,U32,U32);

void f2523(wasmcomponentldInstance*,U32,U32);

void f2524(wasmcomponentldInstance*,U32,U32);

void f2525(wasmcomponentldInstance*,U32,U32);

void f2526(wasmcomponentldInstance*,U32,U32);

void f2527(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2528(wasmcomponentldInstance*,U32,U32);

void f2529(wasmcomponentldInstance*,U32,U32);

void f2530(wasmcomponentldInstance*,U32,U32);

void f2531(wasmcomponentldInstance*,U32,U32);

void f2532(wasmcomponentldInstance*,U32,U32);

void f2533(wasmcomponentldInstance*,U32,U32);

void f2534(wasmcomponentldInstance*,U32,U32);

void f2535(wasmcomponentldInstance*,U32,U32);

void f2536(wasmcomponentldInstance*,U32,U32);

void f2537(wasmcomponentldInstance*,U32,U32);

void f2538(wasmcomponentldInstance*,U32,U32);

void f2539(wasmcomponentldInstance*,U32,U32);

void f2540(wasmcomponentldInstance*,U32,U32);

void f2541(wasmcomponentldInstance*,U32,U32);

void f2542(wasmcomponentldInstance*,U32,U32);

void f2543(wasmcomponentldInstance*,U32,U32);

void f2544(wasmcomponentldInstance*,U32,U32);

void f2545(wasmcomponentldInstance*,U32,U32);

void f2546(wasmcomponentldInstance*,U32,U32);

void f2547(wasmcomponentldInstance*,U32,U32);

void f2548(wasmcomponentldInstance*,U32,U32);

void f2549(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2550(wasmcomponentldInstance*,U32);

void f2551(wasmcomponentldInstance*,U32);

void f2552(wasmcomponentldInstance*,U32);

void f2553(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2554(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2555(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2556(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2557(wasmcomponentldInstance*,U32,U32);

void f2558(wasmcomponentldInstance*,U32,U32);

void f2559(wasmcomponentldInstance*,U32,U32);

void f2560(wasmcomponentldInstance*,U32,U32);

void f2561(wasmcomponentldInstance*,U32,U32);

void f2562(wasmcomponentldInstance*,U32,U32);

void f2563(wasmcomponentldInstance*,U32,U32);

U32 f2564(wasmcomponentldInstance*,U32,U32);

void f2565(wasmcomponentldInstance*,U32,U32);

void f2566(wasmcomponentldInstance*,U32,U32);

void f2567(wasmcomponentldInstance*,U32,U32);

void f2568(wasmcomponentldInstance*,U32,U32);

void f2569(wasmcomponentldInstance*,U32,U32);

void f2570(wasmcomponentldInstance*,U32,U32);

void f2571(wasmcomponentldInstance*,U32,U32);

void f2572(wasmcomponentldInstance*,U32,U32);

void f2573(wasmcomponentldInstance*,U32,U32,U32);

U32 f2574(wasmcomponentldInstance*,U32,U32);

U32 f2575(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2576(wasmcomponentldInstance*,U32,U32,U32);

U32 f2577(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2578(wasmcomponentldInstance*,U32,U32,U32);

void f2579(wasmcomponentldInstance*,U32);

void f2580(wasmcomponentldInstance*,U32);

void f2581(wasmcomponentldInstance*,U32);

void f2582(wasmcomponentldInstance*,U32);

void f2583(wasmcomponentldInstance*,U32);

void f2584(wasmcomponentldInstance*,U32);

void f2585(wasmcomponentldInstance*,U32);

void f2586(wasmcomponentldInstance*,U32);

void f2587(wasmcomponentldInstance*,U32,U32);

void f2588(wasmcomponentldInstance*,U32,U32);

void f2589(wasmcomponentldInstance*,U32,U32);

void f2590(wasmcomponentldInstance*,U32,U32);

void f2591(wasmcomponentldInstance*,U32,U32);

void f2592(wasmcomponentldInstance*,U32,U32);

void f2593(wasmcomponentldInstance*,U32,U32);

void f2594(wasmcomponentldInstance*,U32,U32);

void f2595(wasmcomponentldInstance*,U32,U32);

void f2596(wasmcomponentldInstance*,U32,U32);

void f2597(wasmcomponentldInstance*,U32,U32);

void f2598(wasmcomponentldInstance*,U32,U32);

void f2599(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2600(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2601(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2602(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2603(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2604(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2605(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2606(wasmcomponentldInstance*,U32,U32);

U32 f2607(wasmcomponentldInstance*,U32);

U32 f2608(wasmcomponentldInstance*);

void f2609(wasmcomponentldInstance*);

U32 f2610(wasmcomponentldInstance*,U32,U32);

void f2611(wasmcomponentldInstance*,U32);

void f2612(wasmcomponentldInstance*,U32);

void f2613(wasmcomponentldInstance*,U32);

void f2614(wasmcomponentldInstance*,U32);

void f2615(wasmcomponentldInstance*,U32);

void f2616(wasmcomponentldInstance*,U32);

void f2617(wasmcomponentldInstance*,U32);

void f2618(wasmcomponentldInstance*,U32);

void f2619(wasmcomponentldInstance*,U32);

void f2620(wasmcomponentldInstance*,U32);

void f2621(wasmcomponentldInstance*,U32);

void f2622(wasmcomponentldInstance*,U32);

void f2623(wasmcomponentldInstance*,U32);

void f2624(wasmcomponentldInstance*,U32);

void f2625(wasmcomponentldInstance*,U32);

void f2626(wasmcomponentldInstance*,U32);

void f2627(wasmcomponentldInstance*,U32);

void f2628(wasmcomponentldInstance*,U32);

void f2629(wasmcomponentldInstance*,U32);

U32 f2630(wasmcomponentldInstance*,U32,U32);

void f2631(wasmcomponentldInstance*,U32,U32);

U32 f2632(wasmcomponentldInstance*,U32,U32);

U32 f2633(wasmcomponentldInstance*,U32,U32);

U32 f2634(wasmcomponentldInstance*,U32);

U32 f2635(wasmcomponentldInstance*,U32,U32);

void f2636(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2637(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2638(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2639(wasmcomponentldInstance*,U32,U32,U32);

void f2640(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2641(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2642(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2643(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2644(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2645(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2646(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2647(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2648(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2649(wasmcomponentldInstance*,U32,U32);

U32 f2650(wasmcomponentldInstance*,U32,U32,U32);

U32 f2651(wasmcomponentldInstance*,U32,U32);

void f2652(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f2653(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2654(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2655(wasmcomponentldInstance*,U32);

U32 f2656(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2657(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f2658(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2659(wasmcomponentldInstance*,U32,U32,U32);

void f2660(wasmcomponentldInstance*,U32);

U32 f2661(wasmcomponentldInstance*,U32,U32,U32);

void f2662(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32);

void f2663(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2664(wasmcomponentldInstance*,U32,U32,U32);

U32 f2665(wasmcomponentldInstance*,U32,U32);

void f2666(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f2667(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f2668(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

void f2669(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f2670(wasmcomponentldInstance*,U32,U32);

void f2671(wasmcomponentldInstance*,U32,U32);

U32 f2672(wasmcomponentldInstance*,U32,U32);

void f2673(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2674(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f2675(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f2676(wasmcomponentldInstance*,U32,U32);

U32 f2677(wasmcomponentldInstance*,U32,U32);

void f2678(wasmcomponentldInstance*,U32,U32,U32);

void f2679(wasmcomponentldInstance*,U32,U32,U32);

void f2680(wasmcomponentldInstance*,U32,U32);

void f2681(wasmcomponentldInstance*,U32,U32,U32);

void f2682(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2683(wasmcomponentldInstance*,U32,U32);

U32 f2684(wasmcomponentldInstance*,U32,U32);

U32 f2685(wasmcomponentldInstance*,U32,U32);

U32 f2686(wasmcomponentldInstance*,U32,U32);

U32 f2687(wasmcomponentldInstance*,U32,U32);

U32 f2688(wasmcomponentldInstance*,U32,U32);

U32 f2689(wasmcomponentldInstance*,U32,U32);

U32 f2690(wasmcomponentldInstance*,U32,U32);

void f2691(wasmcomponentldInstance*,U32);

void f2692(wasmcomponentldInstance*,U32,U32,U32);

void f2693(wasmcomponentldInstance*,U32,U32,U32);

void f2694(wasmcomponentldInstance*,U32);

void f2695(wasmcomponentldInstance*,U32);

void f2696(wasmcomponentldInstance*,U32);

void f2697(wasmcomponentldInstance*,U32);

void f2698(wasmcomponentldInstance*,U32);

void f2699(wasmcomponentldInstance*,U32);

void f2700(wasmcomponentldInstance*,U32);

void f2701(wasmcomponentldInstance*,U32);

void f2702(wasmcomponentldInstance*,U32);

void f2703(wasmcomponentldInstance*,U32);

void f2704(wasmcomponentldInstance*,U32);

void f2705(wasmcomponentldInstance*,U32);

void f2706(wasmcomponentldInstance*,U32);

void f2707(wasmcomponentldInstance*,U32);

void f2708(wasmcomponentldInstance*,U32);

void f2709(wasmcomponentldInstance*,U32);

void f2710(wasmcomponentldInstance*,U32);

void f2711(wasmcomponentldInstance*,U32);

void f2712(wasmcomponentldInstance*,U32);

void f2713(wasmcomponentldInstance*,U32);

void f2714(wasmcomponentldInstance*,U32);

void f2715(wasmcomponentldInstance*,U32);

void f2716(wasmcomponentldInstance*,U32,U32,U32);

void f2717(wasmcomponentldInstance*,U32,U32,U32);

void f2718(wasmcomponentldInstance*,U32,U32,U32);

void f2719(wasmcomponentldInstance*,U32,U32,U32);

void f2720(wasmcomponentldInstance*,U32,U32,U32);

void f2721(wasmcomponentldInstance*,U32,U32,U32);

void f2722(wasmcomponentldInstance*,U32,U32,U32);

void f2723(wasmcomponentldInstance*,U32,U32,U32);

void f2724(wasmcomponentldInstance*,U32,U32,U32);

void f2725(wasmcomponentldInstance*,U32,U32,U32);

void f2726(wasmcomponentldInstance*,U32,U32,U32);

void f2727(wasmcomponentldInstance*,U32,U32,U32);

void f2728(wasmcomponentldInstance*,U32,U32,U32);

void f2729(wasmcomponentldInstance*,U32,U32,U32);

void f2730(wasmcomponentldInstance*,U32,U32,U32);

void f2731(wasmcomponentldInstance*,U32,U32,U32);

void f2732(wasmcomponentldInstance*,U32,U32,U32);

void f2733(wasmcomponentldInstance*,U32,U32,U32);

void f2734(wasmcomponentldInstance*,U32,U32,U32);

void f2735(wasmcomponentldInstance*,U32,U32);

void f2736(wasmcomponentldInstance*,U32,U32);

void f2737(wasmcomponentldInstance*,U32);

void f2738(wasmcomponentldInstance*,U32);

void f2739(wasmcomponentldInstance*,U32);

void f2740(wasmcomponentldInstance*,U32);

void f2741(wasmcomponentldInstance*,U32);

void f2742(wasmcomponentldInstance*,U32);

void f2743(wasmcomponentldInstance*,U32);

void f2744(wasmcomponentldInstance*,U32);

void f2745(wasmcomponentldInstance*,U32);

void f2746(wasmcomponentldInstance*,U32);

void f2747(wasmcomponentldInstance*,U32,U32,U32);

U32 f2748(wasmcomponentldInstance*,U32,U32,U64);

void f2749(wasmcomponentldInstance*,U32,U32,U32);

void f2750(wasmcomponentldInstance*,U32,U32,U64,U32);

void f2751(wasmcomponentldInstance*,U32,U32,U64,U32);

void f2752(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2753(wasmcomponentldInstance*,U32,U32,U32);

void f2754(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2755(wasmcomponentldInstance*,U32,U32,U32);

void f2756(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2757(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2758(wasmcomponentldInstance*,U32,U32,U32);

void f2759(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2760(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2761(wasmcomponentldInstance*,U32,U32,U32);

void f2762(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2763(wasmcomponentldInstance*,U32,U32,U32);

void f2764(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2765(wasmcomponentldInstance*,U32,U32,U32);

void f2766(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2767(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2768(wasmcomponentldInstance*,U32,U32,U32);

void f2769(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2770(wasmcomponentldInstance*,U32,U32,U32);

void f2771(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2772(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2773(wasmcomponentldInstance*,U32,U32,U32);

void f2774(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2775(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2776(wasmcomponentldInstance*,U32,U32,U32);

void f2777(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2778(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2779(wasmcomponentldInstance*,U32,U32,U32);

void f2780(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2781(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2782(wasmcomponentldInstance*,U32,U32,U32);

void f2783(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2784(wasmcomponentldInstance*,U32,U32,U32);

void f2785(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2786(wasmcomponentldInstance*,U32,U32,U32);

void f2787(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2788(wasmcomponentldInstance*,U32,U32,U32);

void f2789(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2790(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2791(wasmcomponentldInstance*,U32,U32,U32);

void f2792(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2793(wasmcomponentldInstance*,U32,U32,U32);

void f2794(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2795(wasmcomponentldInstance*,U32,U32,U32);

void f2796(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2797(wasmcomponentldInstance*,U32,U32,U32);

void f2798(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2799(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2800(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2801(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2802(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2803(wasmcomponentldInstance*,U32,U32,U32);

void f2804(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2805(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2806(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2807(wasmcomponentldInstance*,U32,U32,U32);

void f2808(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f2809(wasmcomponentldInstance*,U32,U32,U32);

U32 f2810(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2811(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f2812(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f2813(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f2814(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f2815(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f2816(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f2817(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f2818(wasmcomponentldInstance*,U32,U32);

void f2819(wasmcomponentldInstance*,U32,U32);

void f2820(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2821(wasmcomponentldInstance*,U32,U32);

U32 f2822(wasmcomponentldInstance*,U32,U32);

U32 f2823(wasmcomponentldInstance*,U32,U32);

U32 f2824(wasmcomponentldInstance*,U32,U32);

U32 f2825(wasmcomponentldInstance*,U32,U32);

U32 f2826(wasmcomponentldInstance*,U32,U32);

void f2827(wasmcomponentldInstance*,U32,U32,U32);

void f2828(wasmcomponentldInstance*,U32,U32,U32);

void f2829(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2830(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2831(wasmcomponentldInstance*,U32,U32);

U32 f2832(wasmcomponentldInstance*,U32,U32);

U32 f2833(wasmcomponentldInstance*,U32,U32);

void f2834(wasmcomponentldInstance*,U32,U32,U32);

void f2835(wasmcomponentldInstance*,U32,U32,U32);

void f2836(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2837(wasmcomponentldInstance*,U32,U32,U32);

void f2838(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2839(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2840(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2841(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2842(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2843(wasmcomponentldInstance*,U32,U32,U32);

void f2844(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2845(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2846(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2847(wasmcomponentldInstance*,U32,U32);

void f2848(wasmcomponentldInstance*,U32,U32);

void f2849(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2850(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2851(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2852(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2853(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2854(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2855(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2856(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2857(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2858(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2859(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2860(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2861(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2862(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2863(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2864(wasmcomponentldInstance*,U32,U32,U32);

void f2865(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2866(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2867(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2868(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2869(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2870(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2871(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2872(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2873(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f2874(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f2875(wasmcomponentldInstance*,U32,U32);

void f2876(wasmcomponentldInstance*,U32,U32);

void f2877(wasmcomponentldInstance*,U32,U32);

U32 f2878(wasmcomponentldInstance*,U32,U32);

U32 f2879(wasmcomponentldInstance*,U32,U32,U32);

U32 f2880(wasmcomponentldInstance*,U32,U32,U32);

U32 f2881(wasmcomponentldInstance*,U32,U32,U32);

void f2882(wasmcomponentldInstance*,U32);

U32 f2883(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2884(wasmcomponentldInstance*,U32,U32,U32);

U32 f2885(wasmcomponentldInstance*,U32,U32);

U32 f2886(wasmcomponentldInstance*,U32,U32);

U32 f2887(wasmcomponentldInstance*,U32,U32);

U32 f2888(wasmcomponentldInstance*,U32,U32);

U32 f2889(wasmcomponentldInstance*,U32,U32);

U32 f2890(wasmcomponentldInstance*,U32,U32);

U32 f2891(wasmcomponentldInstance*,U32,U32);

void f2892(wasmcomponentldInstance*,U32);

void f2893(wasmcomponentldInstance*,U32);

void f2894(wasmcomponentldInstance*,U32);

void f2895(wasmcomponentldInstance*,U32);

void f2896(wasmcomponentldInstance*,U32);

void f2897(wasmcomponentldInstance*,U32);

void f2898(wasmcomponentldInstance*,U32);

void f2899(wasmcomponentldInstance*,U32);

void f2900(wasmcomponentldInstance*,U32);

void f2901(wasmcomponentldInstance*,U32);

void f2902(wasmcomponentldInstance*,U32);

void f2903(wasmcomponentldInstance*,U32);

void f2904(wasmcomponentldInstance*,U32);

void f2905(wasmcomponentldInstance*,U32,U32);

void f2906(wasmcomponentldInstance*,U32,U32);

void f2907(wasmcomponentldInstance*,U32,U32);

void f2908(wasmcomponentldInstance*,U32,U32,U32);

void f2909(wasmcomponentldInstance*,U32,U32,U32);

void f2910(wasmcomponentldInstance*,U32,U32);

void f2911(wasmcomponentldInstance*,U32,U32);

void f2912(wasmcomponentldInstance*,U32,U32);

void f2913(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f2914(wasmcomponentldInstance*,U32,U32,U32);

U32 f2915(wasmcomponentldInstance*,U32,U32);

U32 f2916(wasmcomponentldInstance*,U32,U32);

U32 f2917(wasmcomponentldInstance*,U32,U32,U32);

U32 f2918(wasmcomponentldInstance*,U32,U32);

U32 f2919(wasmcomponentldInstance*,U32,U32);

U32 f2920(wasmcomponentldInstance*,U32,U32);

U32 f2921(wasmcomponentldInstance*,U32,U32);

void f2922(wasmcomponentldInstance*,U32,U32);

void f2923(wasmcomponentldInstance*,U32,U32);

void f2924(wasmcomponentldInstance*,U32,U32);

void f2925(wasmcomponentldInstance*,U32,U32);

void f2926(wasmcomponentldInstance*,U32,U32);

void f2927(wasmcomponentldInstance*,U32,U32);

void f2928(wasmcomponentldInstance*,U32,U32);

void f2929(wasmcomponentldInstance*,U32,U32);

U32 f2930(wasmcomponentldInstance*,U32);

void f2931(wasmcomponentldInstance*,U32,U32);

void f2932(wasmcomponentldInstance*,U32,U32);

void f2933(wasmcomponentldInstance*,U32,U32);

void f2934(wasmcomponentldInstance*,U32,U32);

void f2935(wasmcomponentldInstance*,U32,U32);

void f2936(wasmcomponentldInstance*,U32,U32);

void f2937(wasmcomponentldInstance*,U32,U32);

void f2938(wasmcomponentldInstance*,U32,U32);

U32 f2939(wasmcomponentldInstance*,U32,U32);

U32 f2940(wasmcomponentldInstance*,U32,U32,U32);

U32 f2941(wasmcomponentldInstance*,U32);

U32 f2942(wasmcomponentldInstance*,U32,U32);

U32 f2943(wasmcomponentldInstance*,U32,U32);

U32 f2944(wasmcomponentldInstance*,U32,U32,U32);

U32 f2945(wasmcomponentldInstance*,U32,U32);

U32 f2946(wasmcomponentldInstance*,U32);

U32 f2947(wasmcomponentldInstance*,U32,U32);

U32 f2948(wasmcomponentldInstance*,U32);

void f2949(wasmcomponentldInstance*,U32,U32);

U32 f2950(wasmcomponentldInstance*,U32,U32);

U32 f2951(wasmcomponentldInstance*,U32,U32);

U32 f2952(wasmcomponentldInstance*,U32,U32);

U32 f2953(wasmcomponentldInstance*,U32,U32);

U32 f2954(wasmcomponentldInstance*,U32,U32);

void f2955(wasmcomponentldInstance*,U32,U32);

U32 f2956(wasmcomponentldInstance*,U32,U32);

U32 f2957(wasmcomponentldInstance*,U32,U32);

void f2958(wasmcomponentldInstance*,U32,U32);

void f2959(wasmcomponentldInstance*,U32,U32,U32);

void f2960(wasmcomponentldInstance*,U32,U32);

U32 f2961(wasmcomponentldInstance*,U32,U32);

void f2962(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f2963(wasmcomponentldInstance*,U32,U32);

void f2964(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f2965(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2966(wasmcomponentldInstance*,U32,U32,U32);

U32 f2967(wasmcomponentldInstance*,U32,U32);

U32 f2968(wasmcomponentldInstance*,U32,U32);

U32 f2969(wasmcomponentldInstance*,U32,U32);

void f2970(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2971(wasmcomponentldInstance*,U32,U32,U32);

void f2972(wasmcomponentldInstance*,U32,U32,U32);

void f2973(wasmcomponentldInstance*,U32,U32,U32);

void f2974(wasmcomponentldInstance*,U32,U32,U32);

void f2975(wasmcomponentldInstance*,U32,U32,U32);

void f2976(wasmcomponentldInstance*,U32,U32,U32);

void f2977(wasmcomponentldInstance*,U32,U32,U32);

U32 f2978(wasmcomponentldInstance*,U32,U32);

U32 f2979(wasmcomponentldInstance*,U32,U32);

U32 f2980(wasmcomponentldInstance*,U32,U32);

U32 f2981(wasmcomponentldInstance*,U32,U32);

U32 f2982(wasmcomponentldInstance*,U32,U32,U32);

U32 f2983(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2984(wasmcomponentldInstance*,U32,U32,U32);

U32 f2985(wasmcomponentldInstance*,U32,U32,U32);

U32 f2986(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2987(wasmcomponentldInstance*,U32,U32,U32);

U32 f2988(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2989(wasmcomponentldInstance*,U32,U32,U32);

U32 f2990(wasmcomponentldInstance*,U32,U32,U32);

U32 f2991(wasmcomponentldInstance*,U32,U32,U32);

U32 f2992(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f2993(wasmcomponentldInstance*,U32,U32,U32,U32);

void f2994(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f2995(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f2996(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f2997(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f2998(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f2999(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3000(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3001(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3002(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3003(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3004(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3005(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3006(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3007(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3008(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3009(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3010(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3011(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3012(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3013(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3014(wasmcomponentldInstance*,U32,U32);

void f3015(wasmcomponentldInstance*,U32,U32);

void f3016(wasmcomponentldInstance*,U32,U32);

void f3017(wasmcomponentldInstance*,U32,U32);

void f3018(wasmcomponentldInstance*,U32,U32,U32);

void f3019(wasmcomponentldInstance*,U32,U32);

void f3020(wasmcomponentldInstance*,U32,U32);

void f3021(wasmcomponentldInstance*,U32,U32,U32);

void f3022(wasmcomponentldInstance*,U32,U32,U32);

void f3023(wasmcomponentldInstance*,U32,U32);

void f3024(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3025(wasmcomponentldInstance*,U32,U32,U32);

void f3026(wasmcomponentldInstance*,U32,U32,U32);

void f3027(wasmcomponentldInstance*,U32,U32,U32);

void f3028(wasmcomponentldInstance*,U32,U32);

void f3029(wasmcomponentldInstance*,U32,U32);

void f3030(wasmcomponentldInstance*,U32,U32,U32);

void f3031(wasmcomponentldInstance*,U32,U32,U32);

void f3032(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3033(wasmcomponentldInstance*,U32,U32,U32);

void f3034(wasmcomponentldInstance*,U32,U32,U32);

U32 f3035(wasmcomponentldInstance*,U32,U32);

void f3036(wasmcomponentldInstance*,U32,U32,U32);

void f3037(wasmcomponentldInstance*,U32,U32,U32);

void f3038(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3039(wasmcomponentldInstance*,U32,U32);

void f3040(wasmcomponentldInstance*,U32,U32);

U32 f3041(wasmcomponentldInstance*,U32,U32);

U32 f3042(wasmcomponentldInstance*,U32,U32);

U32 f3043(wasmcomponentldInstance*,U32,U32);

U32 f3044(wasmcomponentldInstance*,U32,U32);

void f3045(wasmcomponentldInstance*,U32);

void f3046(wasmcomponentldInstance*,U32);

void f3047(wasmcomponentldInstance*,U32);

void f3048(wasmcomponentldInstance*,U32,U32);

void f3049(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3050(wasmcomponentldInstance*,U32,U32);

void f3051(wasmcomponentldInstance*,U32,U32);

void f3052(wasmcomponentldInstance*,U32,U32);

void f3053(wasmcomponentldInstance*,U32,U32);

void f3054(wasmcomponentldInstance*,U32,U32);

void f3055(wasmcomponentldInstance*,U32,U32);

void f3056(wasmcomponentldInstance*,U32,U32);

void f3057(wasmcomponentldInstance*,U32,U32);

void f3058(wasmcomponentldInstance*,U32,U32);

void f3059(wasmcomponentldInstance*,U32,U32);

void f3060(wasmcomponentldInstance*,U32,U32);

void f3061(wasmcomponentldInstance*,U32,U32);

void f3062(wasmcomponentldInstance*,U32,U32);

void f3063(wasmcomponentldInstance*,U32,U32);

void f3064(wasmcomponentldInstance*,U32,U32);

void f3065(wasmcomponentldInstance*,U32,U32);

void f3066(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3067(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3068(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3069(wasmcomponentldInstance*,U32);

U32 f3070(wasmcomponentldInstance*,U32,U32);

void f3071(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3072(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3073(wasmcomponentldInstance*,U32);

void f3074(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3075(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3076(wasmcomponentldInstance*,U32,U32,U32);

void f3077(wasmcomponentldInstance*,U32,U32,U32);

void f3078(wasmcomponentldInstance*,U32,U32);

void f3079(wasmcomponentldInstance*,U32,U32);

void f3080(wasmcomponentldInstance*,U32,U32,U32);

void f3081(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3082(wasmcomponentldInstance*,U32,U32);

void f3083(wasmcomponentldInstance*,U32,U32,U32);

U32 f3084(wasmcomponentldInstance*,U32,U32);

void f3085(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3086(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3087(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3088(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3089(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3090(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3091(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3092(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3093(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3094(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3095(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3096(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3097(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f3098(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3099(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3100(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3101(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3102(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3103(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3104(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3105(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3106(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3107(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3108(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3109(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3110(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3111(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3112(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3113(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3114(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3115(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3116(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3117(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3118(wasmcomponentldInstance*,U32,U32);

void f3119(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3120(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3121(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3122(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3123(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3124(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3125(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3126(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3127(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3128(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3129(wasmcomponentldInstance*,U32,U32);

void f3130(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3131(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3132(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3133(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3134(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3135(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3136(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3137(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3138(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3139(wasmcomponentldInstance*,U32,U32);

void f3140(wasmcomponentldInstance*,U32,U32,U32);

void f3141(wasmcomponentldInstance*,U32,U32);

void f3142(wasmcomponentldInstance*,U32,U32);

void f3143(wasmcomponentldInstance*,U32,U32);

void f3144(wasmcomponentldInstance*,U32);

void f3145(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3146(wasmcomponentldInstance*,U32,U32,U32);

void f3147(wasmcomponentldInstance*,U32,U32,U32);

U32 f3148(wasmcomponentldInstance*,U32,U32,U32);

U32 f3149(wasmcomponentldInstance*,U32,U32,U32);

U32 f3150(wasmcomponentldInstance*,U32,U32,U32);

U32 f3151(wasmcomponentldInstance*,U32,U32,U32);

U32 f3152(wasmcomponentldInstance*,U32,U32,U32);

U32 f3153(wasmcomponentldInstance*,U32,U32);

U32 f3154(wasmcomponentldInstance*,U32,U32);

U32 f3155(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3156(wasmcomponentldInstance*,U32,U32,U32);

U32 f3157(wasmcomponentldInstance*,U32,U32,U32);

U32 f3158(wasmcomponentldInstance*,U32,U32);

void f3159(wasmcomponentldInstance*,U32,U32,U32);

void f3160(wasmcomponentldInstance*,U32,U32,U32);

void f3161(wasmcomponentldInstance*,U32,U32);

void f3162(wasmcomponentldInstance*,U32,U32,U32);

void f3163(wasmcomponentldInstance*,U32,U32);

void f3164(wasmcomponentldInstance*,U32,U32);

void f3165(wasmcomponentldInstance*,U32,U32);

void f3166(wasmcomponentldInstance*,U32,U32,U32);

U32 f3167(wasmcomponentldInstance*,U32,U32,U32);

U32 f3168(wasmcomponentldInstance*,U32,U32,U32);

U32 f3169(wasmcomponentldInstance*,U32,U32);

U32 f3170(wasmcomponentldInstance*,U32,U32);

U32 f3171(wasmcomponentldInstance*,U32,U32,U32);

U32 f3172(wasmcomponentldInstance*,U32,U32,U32);

void f3173(wasmcomponentldInstance*,U32,U32,U32);

void f3174(wasmcomponentldInstance*,U32,U32,U32);

void f3175(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3176(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3177(wasmcomponentldInstance*,U32);

U32 f3178(wasmcomponentldInstance*,U32,U32);

void f3179(wasmcomponentldInstance*,U32,U32);

void f3180(wasmcomponentldInstance*,U32,U32);

void f3181(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3182(wasmcomponentldInstance*,U32,U32);

U32 f3183(wasmcomponentldInstance*,U32,U32);

U32 f3184(wasmcomponentldInstance*,U32,U32);

U32 f3185(wasmcomponentldInstance*,U32,U32);

U32 f3186(wasmcomponentldInstance*,U32,U32);

U32 f3187(wasmcomponentldInstance*,U32,U32);

U32 f3188(wasmcomponentldInstance*,U32,U32);

U32 f3189(wasmcomponentldInstance*,U32);

void f3190(wasmcomponentldInstance*,U32);

void f3191(wasmcomponentldInstance*,U32);

void f3192(wasmcomponentldInstance*,U32);

void f3193(wasmcomponentldInstance*,U32);

void f3194(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3195(wasmcomponentldInstance*,U32,U32);

void f3196(wasmcomponentldInstance*,U32,U32);

void f3197(wasmcomponentldInstance*,U32,U32);

void f3198(wasmcomponentldInstance*,U32,U32,U32);

void f3199(wasmcomponentldInstance*,U32,U32);

U32 f3200(wasmcomponentldInstance*,U32,U32,U32);

U32 f3201(wasmcomponentldInstance*,U32,U32,U32);

U32 f3202(wasmcomponentldInstance*,U32);

U32 f3203(wasmcomponentldInstance*,U32,U32);

U32 f3204(wasmcomponentldInstance*,U32,U32);

void f3205(wasmcomponentldInstance*,U32);

void f3206(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3207(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3208(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3209(wasmcomponentldInstance*,U32,U32);

void f3210(wasmcomponentldInstance*,U32,U32,U32);

void f3211(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3212(wasmcomponentldInstance*,U32,U32,U32);

void f3213(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3214(wasmcomponentldInstance*,U32);

U32 f3215(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3216(wasmcomponentldInstance*,U32,U32);

U32 f3217(wasmcomponentldInstance*,U32,U32);

U32 f3218(wasmcomponentldInstance*,U32,U32);

U32 f3219(wasmcomponentldInstance*,U32);

void f3220(wasmcomponentldInstance*,U32);

void f3221(wasmcomponentldInstance*,U32,U32,U32);

U32 f3222(wasmcomponentldInstance*,U32,U32);

U32 f3223(wasmcomponentldInstance*,U32,U32);

U32 f3224(wasmcomponentldInstance*,U32,U32);

U32 f3225(wasmcomponentldInstance*,U32);

void f3226(wasmcomponentldInstance*,U32);

void f3227(wasmcomponentldInstance*,U32);

void f3228(wasmcomponentldInstance*,U32);

void f3229(wasmcomponentldInstance*,U32);

void f3230(wasmcomponentldInstance*,U32);

void f3231(wasmcomponentldInstance*,U32);

void f3232(wasmcomponentldInstance*,U32);

void f3233(wasmcomponentldInstance*,U32);

void f3234(wasmcomponentldInstance*,U32,U32);

void f3235(wasmcomponentldInstance*,U32,U32);

void f3236(wasmcomponentldInstance*,U32,U32);

void f3237(wasmcomponentldInstance*,U32,U32);

void f3238(wasmcomponentldInstance*,U32,U32);

void f3239(wasmcomponentldInstance*,U32,U32);

void f3240(wasmcomponentldInstance*,U32,U32,U32);

void f3241(wasmcomponentldInstance*,U32,U32);

void f3242(wasmcomponentldInstance*,U32,U32);

void f3243(wasmcomponentldInstance*,U32,U32);

void f3244(wasmcomponentldInstance*,U32,U32);

void f3245(wasmcomponentldInstance*,U32,U32);

void f3246(wasmcomponentldInstance*,U32,U32);

void f3247(wasmcomponentldInstance*,U32,U32);

void f3248(wasmcomponentldInstance*,U32,U32);

void f3249(wasmcomponentldInstance*,U32,U32);

void f3250(wasmcomponentldInstance*,U32,U32);

void f3251(wasmcomponentldInstance*,U32,U32);

void f3252(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3253(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3254(wasmcomponentldInstance*,U32,U32);

U32 f3255(wasmcomponentldInstance*,U32,U32);

U32 f3256(wasmcomponentldInstance*,U32,U32,U32);

U32 f3257(wasmcomponentldInstance*,U32,U32);

U32 f3258(wasmcomponentldInstance*,U32,U32);

U32 f3259(wasmcomponentldInstance*,U32,U32);

void f3260(wasmcomponentldInstance*,U32);

void f3261(wasmcomponentldInstance*,U32);

void f3262(wasmcomponentldInstance*,U32);

void f3263(wasmcomponentldInstance*,U32);

void f3264(wasmcomponentldInstance*,U32);

void f3265(wasmcomponentldInstance*,U32);

void f3266(wasmcomponentldInstance*,U32);

U32 f3267(wasmcomponentldInstance*,U32,U64,U64);

U32 f3268(wasmcomponentldInstance*,U32,U64,U64);

U32 f3269(wasmcomponentldInstance*,U32,U64,U64);

U32 f3270(wasmcomponentldInstance*,U32,U64,U64);

U32 f3271(wasmcomponentldInstance*,U32,U64,U64);

U32 f3272(wasmcomponentldInstance*,U32,U64,U64);

U32 f3273(wasmcomponentldInstance*,U32);

U32 f3274(wasmcomponentldInstance*,U32);

void f3275(wasmcomponentldInstance*,U32,U64,U64);

void f3276(wasmcomponentldInstance*,U32,U64,U64);

void f3277(wasmcomponentldInstance*,U32,U64,U64);

void f3278(wasmcomponentldInstance*,U32,U64,U64);

void f3279(wasmcomponentldInstance*,U32,U64,U64);

void f3280(wasmcomponentldInstance*,U32,U64,U64);

U32 f3281(wasmcomponentldInstance*,U32,U64,U64);

U32 f3282(wasmcomponentldInstance*,U32,U64,U64);

void f3283(wasmcomponentldInstance*,U32,U64,U64);

void f3284(wasmcomponentldInstance*,U32,U64,U64);

void f3285(wasmcomponentldInstance*,U32,U32);

void f3286(wasmcomponentldInstance*,U32,U32);

void f3287(wasmcomponentldInstance*,U32,U32);

void f3288(wasmcomponentldInstance*,U32,U32);

void f3289(wasmcomponentldInstance*,U32,U32);

void f3290(wasmcomponentldInstance*,U32,U32);

void f3291(wasmcomponentldInstance*,U32,U32);

void f3292(wasmcomponentldInstance*,U32,U32);

void f3293(wasmcomponentldInstance*,U32,U32);

void f3294(wasmcomponentldInstance*,U32,U32);

U32 f3295(wasmcomponentldInstance*,U32,U32);

U32 f3296(wasmcomponentldInstance*,U32,U32);

U32 f3297(wasmcomponentldInstance*,U32,U32);

U32 f3298(wasmcomponentldInstance*,U32,U32);

U32 f3299(wasmcomponentldInstance*,U32,U32);

U32 f3300(wasmcomponentldInstance*,U32,U32);

void f3301(wasmcomponentldInstance*,U32,U32);

U32 f3302(wasmcomponentldInstance*,U32,U32);

U32 f3303(wasmcomponentldInstance*,U32,U32);

void f3304(wasmcomponentldInstance*,U32,U32);

U32 f3305(wasmcomponentldInstance*,U32,U32);

U32 f3306(wasmcomponentldInstance*,U32,U32,U32);

void f3307(wasmcomponentldInstance*,U32);

void f3308(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3309(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3310(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3311(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3312(wasmcomponentldInstance*,U32,U32);

void f3313(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3314(wasmcomponentldInstance*,U32,U32,U32);

U32 f3315(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3316(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3317(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3318(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3319(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3320(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3321(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3322(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3323(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3324(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3325(wasmcomponentldInstance*,U32,U32);

void f3326(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3327(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3328(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3329(wasmcomponentldInstance*,U32,U32);

void f3330(wasmcomponentldInstance*,U32,U32,U32);

U32 f3331(wasmcomponentldInstance*,U32,U32);

void f3332(wasmcomponentldInstance*,U32,U32,U32);

void f3333(wasmcomponentldInstance*,U32,U32,U32);

void f3334(wasmcomponentldInstance*,U32,U32,U32);

void f3335(wasmcomponentldInstance*,U32,U32,U32);

void f3336(wasmcomponentldInstance*,U32,U32);

void f3337(wasmcomponentldInstance*,U32,U32);

void f3338(wasmcomponentldInstance*,U32,U32);

void f3339(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3340(wasmcomponentldInstance*,U32,U32);

U32 f3341(wasmcomponentldInstance*,U32,U32);

U32 f3342(wasmcomponentldInstance*,U32,U32);

void f3343(wasmcomponentldInstance*,U32,U32);

void f3344(wasmcomponentldInstance*,U32,U32);

void f3345(wasmcomponentldInstance*,U32,U32);

void f3346(wasmcomponentldInstance*,U32,U32);

void f3347(wasmcomponentldInstance*,U32,U32);

void f3348(wasmcomponentldInstance*,U32,U32,U32);

void f3349(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3350(wasmcomponentldInstance*,U32,U32);

void f3351(wasmcomponentldInstance*,U32,U32);

U32 f3352(wasmcomponentldInstance*,U32,U32);

U32 f3353(wasmcomponentldInstance*,U32,U32);

U32 f3354(wasmcomponentldInstance*,U32,U32);

U32 f3355(wasmcomponentldInstance*,U32,U32);

U32 f3356(wasmcomponentldInstance*,U32,U32);

U32 f3357(wasmcomponentldInstance*,U32,U32);

U32 f3358(wasmcomponentldInstance*,U32,U32);

U32 f3359(wasmcomponentldInstance*,U32,U32);

U32 f3360(wasmcomponentldInstance*,U32,U32);

U32 f3361(wasmcomponentldInstance*,U32,U32);

U32 f3362(wasmcomponentldInstance*,U32,U32);

U32 f3363(wasmcomponentldInstance*,U32,U32);

U32 f3364(wasmcomponentldInstance*,U32,U32);

U32 f3365(wasmcomponentldInstance*,U32,U32);

U32 f3366(wasmcomponentldInstance*,U32,U32);

U32 f3367(wasmcomponentldInstance*,U32,U32);

U32 f3368(wasmcomponentldInstance*,U32,U32);

U32 f3369(wasmcomponentldInstance*,U32,U32);

U32 f3370(wasmcomponentldInstance*,U32,U32);

U32 f3371(wasmcomponentldInstance*,U32,U32);

U32 f3372(wasmcomponentldInstance*,U32,U32);

U32 f3373(wasmcomponentldInstance*,U32,U32);

U32 f3374(wasmcomponentldInstance*,U32,U32);

U32 f3375(wasmcomponentldInstance*,U32,U32);

U32 f3376(wasmcomponentldInstance*,U32,U32);

U32 f3377(wasmcomponentldInstance*,U32,U32);

U32 f3378(wasmcomponentldInstance*,U32,U32);

U32 f3379(wasmcomponentldInstance*,U32,U32);

U32 f3380(wasmcomponentldInstance*,U32,U32);

U32 f3381(wasmcomponentldInstance*,U32,U32);

U32 f3382(wasmcomponentldInstance*,U32,U32);

U32 f3383(wasmcomponentldInstance*,U32,U32);

U32 f3384(wasmcomponentldInstance*,U32,U32);

U32 f3385(wasmcomponentldInstance*,U32,U32);

U32 f3386(wasmcomponentldInstance*,U32,U32);

U32 f3387(wasmcomponentldInstance*,U32,U32);

U32 f3388(wasmcomponentldInstance*,U32,U32);

U32 f3389(wasmcomponentldInstance*,U32,U32);

U32 f3390(wasmcomponentldInstance*,U32,U32);

U32 f3391(wasmcomponentldInstance*,U32,U32);

U32 f3392(wasmcomponentldInstance*,U32,U32);

U32 f3393(wasmcomponentldInstance*,U32,U32);

U32 f3394(wasmcomponentldInstance*,U32,U32);

U32 f3395(wasmcomponentldInstance*,U32,U32);

U32 f3396(wasmcomponentldInstance*,U32,U32);

U32 f3397(wasmcomponentldInstance*,U32,U32);

U32 f3398(wasmcomponentldInstance*,U32,U32);

U32 f3399(wasmcomponentldInstance*,U32,U32);

U32 f3400(wasmcomponentldInstance*,U32,U32);

U32 f3401(wasmcomponentldInstance*,U32,U32);

U32 f3402(wasmcomponentldInstance*,U32,U32);

U32 f3403(wasmcomponentldInstance*,U32,U32);

void f3404(wasmcomponentldInstance*,U32);

void f3405(wasmcomponentldInstance*,U32);

void f3406(wasmcomponentldInstance*,U32);

U64 f3407(wasmcomponentldInstance*,U32,U32);

void f3408(wasmcomponentldInstance*,U32,U32,U32);

U64 f3409(wasmcomponentldInstance*,U32,U32);

void f3410(wasmcomponentldInstance*,U32,U32);

U64 f3411(wasmcomponentldInstance*,U32,U32);

U64 f3412(wasmcomponentldInstance*,U32,U32);

U64 f3413(wasmcomponentldInstance*,U32,U32);

U64 f3414(wasmcomponentldInstance*,U32,U32);

U64 f3415(wasmcomponentldInstance*,U32,U32);

void f3416(wasmcomponentldInstance*,U32,U32);

U64 f3417(wasmcomponentldInstance*,U32,U32);

U64 f3418(wasmcomponentldInstance*,U32,U32);

void f3419(wasmcomponentldInstance*,U32,U32);

U64 f3420(wasmcomponentldInstance*,U32,U32);

U64 f3421(wasmcomponentldInstance*,U32,U32);

U64 f3422(wasmcomponentldInstance*,U32,U32);

U64 f3423(wasmcomponentldInstance*,U32,U32);

U64 f3424(wasmcomponentldInstance*,U32,U32);

U64 f3425(wasmcomponentldInstance*,U32,U32);

U64 f3426(wasmcomponentldInstance*,U32,U32,U32);

U64 f3427(wasmcomponentldInstance*,U32,U32);

U64 f3428(wasmcomponentldInstance*,U32,U32);

U64 f3429(wasmcomponentldInstance*,U32,U32);

U64 f3430(wasmcomponentldInstance*,U32,U32);

U32 f3431(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3432(wasmcomponentldInstance*,U32,U32,U32);

U32 f3433(wasmcomponentldInstance*,U32,U32);

U32 f3434(wasmcomponentldInstance*,U32,U32);

U32 f3435(wasmcomponentldInstance*,U32,U32);

U32 f3436(wasmcomponentldInstance*,U32,U32);

U32 f3437(wasmcomponentldInstance*,U32,U32);

U32 f3438(wasmcomponentldInstance*,U32,U32);

U32 f3439(wasmcomponentldInstance*,U32,U32);

void f3440(wasmcomponentldInstance*,U32,U32);

void f3441(wasmcomponentldInstance*,U32,U32);

void f3442(wasmcomponentldInstance*,U32,U32);

void f3443(wasmcomponentldInstance*,U32,U64);

void f3444(wasmcomponentldInstance*,U32,U32,U32);

void f3445(wasmcomponentldInstance*,U32,U32);

void f3446(wasmcomponentldInstance*,U32,U32);

void f3447(wasmcomponentldInstance*,U32);

void f3448(wasmcomponentldInstance*,U32,U32);

void f3449(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3450(wasmcomponentldInstance*,U32,U32,U32);

void f3451(wasmcomponentldInstance*,U32,U32,U32);

void f3452(wasmcomponentldInstance*,U32);

void f3453(wasmcomponentldInstance*,U32,U32,U32);

void f3454(wasmcomponentldInstance*,U32,U32);

void f3455(wasmcomponentldInstance*,U32,U32,U32);

void f3456(wasmcomponentldInstance*,U32,U32);

void f3457(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3458(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3459(wasmcomponentldInstance*,U32,U32,U32);

void f3460(wasmcomponentldInstance*,U32,U32,U32);

void f3461(wasmcomponentldInstance*,U32,U32,U32);

U32 f3462(wasmcomponentldInstance*,U32,U32,U32);

U32 f3463(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3464(wasmcomponentldInstance*,U32,U32,U32);

U32 f3465(wasmcomponentldInstance*,U32,U32,U32);

U32 f3466(wasmcomponentldInstance*,U32,U32,U32);

U32 f3467(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3468(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3469(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3470(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3471(wasmcomponentldInstance*,U32,U32);

U32 f3472(wasmcomponentldInstance*,U32,U32);

void f3473(wasmcomponentldInstance*,U32);

void f3474(wasmcomponentldInstance*,U32);

void f3475(wasmcomponentldInstance*,U32);

void f3476(wasmcomponentldInstance*,U32);

void f3477(wasmcomponentldInstance*,U32);

void f3478(wasmcomponentldInstance*,U32);

void f3479(wasmcomponentldInstance*,U32);

void f3480(wasmcomponentldInstance*,U32,U32);

void f3481(wasmcomponentldInstance*,U32,U32);

U32 f3482(wasmcomponentldInstance*,U32,U32);

U32 f3483(wasmcomponentldInstance*,U32,U32);

U32 f3484(wasmcomponentldInstance*,U32,U32);

U32 f3485(wasmcomponentldInstance*,U32,U32);

U32 f3486(wasmcomponentldInstance*,U32,U32,U32);

void f3487(wasmcomponentldInstance*,U32,U32);

U32 f3488(wasmcomponentldInstance*,U32,U32);

U32 f3489(wasmcomponentldInstance*,U32,U32);

U32 f3490(wasmcomponentldInstance*,U32);

void f3491(wasmcomponentldInstance*,U32,U32,U32);

void f3492(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f3493(wasmcomponentldInstance*,U32,U32);

U32 f3494(wasmcomponentldInstance*,U32,U32,U32);

void f3495(wasmcomponentldInstance*,U32,U32);

void f3496(wasmcomponentldInstance*,U32,U32);

void f3497(wasmcomponentldInstance*,U32,U32);

void f3498(wasmcomponentldInstance*,U32,U32);

void f3499(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f3500(wasmcomponentldInstance*,U32,U32,U32);

U32 f3501(wasmcomponentldInstance*,U32,U32,U32);

U32 f3502(wasmcomponentldInstance*,U32,U32,U32);

U32 f3503(wasmcomponentldInstance*,U32,U32,U32);

U32 f3504(wasmcomponentldInstance*,U32,U32,U32);

U32 f3505(wasmcomponentldInstance*,U32,U32,U32);

U32 f3506(wasmcomponentldInstance*,U32,U32,U32);

U32 f3507(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3508(wasmcomponentldInstance*,U32,U32,U32);

U32 f3509(wasmcomponentldInstance*,U32,U32,U32);

U32 f3510(wasmcomponentldInstance*,U32,U32,U32);

U32 f3511(wasmcomponentldInstance*,U32,U32,U32);

U32 f3512(wasmcomponentldInstance*,U32,U32,U32);

U32 f3513(wasmcomponentldInstance*,U32,U32,U32);

U32 f3514(wasmcomponentldInstance*,U32,U32,U32);

U32 f3515(wasmcomponentldInstance*,U32,U32,U32);

U32 f3516(wasmcomponentldInstance*,U32,U32,U32);

void f3517(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3518(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3519(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3520(wasmcomponentldInstance*,U32,U32,U32);

U32 f3521(wasmcomponentldInstance*,U32,U32,U32);

U32 f3522(wasmcomponentldInstance*,U32,U32,U32);

U32 f3523(wasmcomponentldInstance*,U32,U32,U32);

U32 f3524(wasmcomponentldInstance*,U32,U32,U32);

U32 f3525(wasmcomponentldInstance*,U32,U32,U32);

U32 f3526(wasmcomponentldInstance*,U32,U32,U32);

void f3527(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3528(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3529(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3530(wasmcomponentldInstance*,U32,U32);

void f3531(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3532(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3533(wasmcomponentldInstance*,U32,U32);

void f3534(wasmcomponentldInstance*,U32,U32);

void f3535(wasmcomponentldInstance*,U32,U32);

void f3536(wasmcomponentldInstance*,U32,U32);

void f3537(wasmcomponentldInstance*,U32,U32);

void f3538(wasmcomponentldInstance*,U32,U32);

void f3539(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3540(wasmcomponentldInstance*,U32,U32);

void f3541(wasmcomponentldInstance*,U32,U32);

void f3542(wasmcomponentldInstance*,U32,U32);

void f3543(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3544(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

void f3545(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

void f3546(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3547(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3548(wasmcomponentldInstance*,U32,U32,U32);

void f3549(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3550(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

void f3551(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

void f3552(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3553(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3554(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f3555(wasmcomponentldInstance*,U32,U32);

U32 f3556(wasmcomponentldInstance*,U32,U32,U32);

void f3557(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3558(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3559(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3560(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3561(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3562(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

void f3563(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3564(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3565(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3566(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3567(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3568(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3569(wasmcomponentldInstance*,U32,U32,U32);

void f3570(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3571(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3572(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3573(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3574(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3575(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3576(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3577(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3578(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3579(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3580(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3581(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3582(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3583(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3584(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3585(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f3586(wasmcomponentldInstance*,U32,U32);

U32 f3587(wasmcomponentldInstance*,U32,U32);

U32 f3588(wasmcomponentldInstance*,U32,U32);

void f3589(wasmcomponentldInstance*,U32,U32,U32);

U32 f3590(wasmcomponentldInstance*,U32,U32,U64);

void f3591(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f3592(wasmcomponentldInstance*,U32,U32,U32);

void f3593(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f3594(wasmcomponentldInstance*,U32,U32,U32);

U32 f3595(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3596(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U64 f3597(wasmcomponentldInstance*,U32,U32);

void f3598(wasmcomponentldInstance*,U32,U32,U32);

void f3599(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3600(wasmcomponentldInstance*,U32,U32);

void f3601(wasmcomponentldInstance*,U32,U32);

void f3602(wasmcomponentldInstance*,U32,U32);

void f3603(wasmcomponentldInstance*,U32,U32);

void f3604(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3605(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f3606(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

U32 f3607(wasmcomponentldInstance*,U32,U32);

void f3608(wasmcomponentldInstance*,U32);

void f3609(wasmcomponentldInstance*,U32);

void f3610(wasmcomponentldInstance*,U32);

void f3611(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3612(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3613(wasmcomponentldInstance*,U32);

void f3614(wasmcomponentldInstance*,U32);

void f3615(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3616(wasmcomponentldInstance*,U32);

void f3617(wasmcomponentldInstance*,U32);

void f3618(wasmcomponentldInstance*,U32,U32,U32);

void f3619(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3620(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f3621(wasmcomponentldInstance*,U32,U32);

void f3622(wasmcomponentldInstance*,U32,U32);

void f3623(wasmcomponentldInstance*,U32,U32);

void f3624(wasmcomponentldInstance*,U32,U32);

void f3625(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3626(wasmcomponentldInstance*,U32,U32);

void f3627(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3628(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3629(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3630(wasmcomponentldInstance*,U32,U32,U32);

void f3631(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3632(wasmcomponentldInstance*,U32,U32);

void f3633(wasmcomponentldInstance*,U32,U32);

U32 f3634(wasmcomponentldInstance*,U32,U32,U32);

U32 f3635(wasmcomponentldInstance*,U32,U32);

U32 f3636(wasmcomponentldInstance*,U32,U32);

U32 f3637(wasmcomponentldInstance*,U32,U32);

void f3638(wasmcomponentldInstance*,U32);

void f3639(wasmcomponentldInstance*,U32);

void f3640(wasmcomponentldInstance*,U32);

void f3641(wasmcomponentldInstance*,U32,U32);

void f3642(wasmcomponentldInstance*,U32,U32);

void f3643(wasmcomponentldInstance*,U32,U32);

void f3644(wasmcomponentldInstance*,U32,U32);

void f3645(wasmcomponentldInstance*,U32,U32,U32);

void f3646(wasmcomponentldInstance*,U32,U32,U32);

void f3647(wasmcomponentldInstance*,U32,U32);

void f3648(wasmcomponentldInstance*,U32,U32);

U32 f3649(wasmcomponentldInstance*,U32,U32);

void f3650(wasmcomponentldInstance*,U32,U32);

void f3651(wasmcomponentldInstance*,U32);

U32 f3652(wasmcomponentldInstance*,U32);

void f3653(wasmcomponentldInstance*,U32,U32);

U32 f3654(wasmcomponentldInstance*,U32,U64,U64);

void f3655(wasmcomponentldInstance*,U32,U64,U64);

void f3656(wasmcomponentldInstance*,U32,U32);

U32 f3657(wasmcomponentldInstance*,U32,U32);

U32 f3658(wasmcomponentldInstance*,U32);

U32 f3659(wasmcomponentldInstance*,U32,U32);

void f3660(wasmcomponentldInstance*,U32,U32);

U32 f3661(wasmcomponentldInstance*,U32,U32);

U32 f3662(wasmcomponentldInstance*,U32,U32);

U32 f3663(wasmcomponentldInstance*,U32,U32);

void f3664(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3665(wasmcomponentldInstance*,U32,U32);

void f3666(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3667(wasmcomponentldInstance*,U32,U32);

void f3668(wasmcomponentldInstance*,U32,U32);

void f3669(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3670(wasmcomponentldInstance*,U32,U32,U32);

void f3671(wasmcomponentldInstance*,U32);

void f3672(wasmcomponentldInstance*,U32);

void f3673(wasmcomponentldInstance*,U32);

void f3674(wasmcomponentldInstance*,U32);

void f3675(wasmcomponentldInstance*,U32);

void f3676(wasmcomponentldInstance*,U32);

void f3677(wasmcomponentldInstance*,U32);

void f3678(wasmcomponentldInstance*,U32);

void f3679(wasmcomponentldInstance*,U32);

void f3680(wasmcomponentldInstance*,U32);

void f3681(wasmcomponentldInstance*,U32);

U32 f3682(wasmcomponentldInstance*,U32,U32);

U32 f3683(wasmcomponentldInstance*,U32,U32);

U32 f3684(wasmcomponentldInstance*,U32,U32);

void f3685(wasmcomponentldInstance*,U32,U32);

void f3686(wasmcomponentldInstance*,U32,U32);

U32 f3687(wasmcomponentldInstance*,U32,U32);

void f3688(wasmcomponentldInstance*,U32,U32);

U32 f3689(wasmcomponentldInstance*,U32,U32);

U32 f3690(wasmcomponentldInstance*,U32,U32);

U32 f3691(wasmcomponentldInstance*,U32);

U32 f3692(wasmcomponentldInstance*,U32,U32);

void f3693(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3694(wasmcomponentldInstance*,U32,U32,U32);

U32 f3695(wasmcomponentldInstance*,U32,U64,U32);

void f3696(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3697(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3698(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3699(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3700(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3701(wasmcomponentldInstance*,U32,U32,U32);

void f3702(wasmcomponentldInstance*,U32,U32,U32);

U32 f3703(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3704(wasmcomponentldInstance*,U32,U32,U32);

void f3705(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3706(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3707(wasmcomponentldInstance*,U32,U32);

U32 f3708(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3709(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3710(wasmcomponentldInstance*,U32,U32,U32);

U32 f3711(wasmcomponentldInstance*,U32,U32);

U32 f3712(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3713(wasmcomponentldInstance*,U32,U32,U32);

U32 f3714(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3715(wasmcomponentldInstance*,U32,U32,U32);

void f3716(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3717(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3718(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3719(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3720(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3721(wasmcomponentldInstance*,U32,U32);

U32 f3722(wasmcomponentldInstance*,U32,U32,U32);

void f3723(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3724(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3725(wasmcomponentldInstance*,U32,U32,U32);

U32 f3726(wasmcomponentldInstance*,U32,U32);

void f3727(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3728(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3729(wasmcomponentldInstance*,U32,U32,U32);

void f3730(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3731(wasmcomponentldInstance*,U32,U32);

void f3732(wasmcomponentldInstance*,U32,U32,U32);

void f3733(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3734(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3735(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f3736(wasmcomponentldInstance*,U32,U32,U32);

void f3737(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3738(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

void f3739(wasmcomponentldInstance*,U32,U32);

U32 f3740(wasmcomponentldInstance*,U32,U32,U32);

void f3741(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3742(wasmcomponentldInstance*,U32,U32,U32);

void f3743(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3744(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3745(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3746(wasmcomponentldInstance*,U32,U32);

U32 f3747(wasmcomponentldInstance*,U32,U32,U32);

U32 f3748(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3749(wasmcomponentldInstance*,U32);

U32 f3750(wasmcomponentldInstance*,U32,U32,U32);

U32 f3751(wasmcomponentldInstance*,U32,U32);

void f3752(wasmcomponentldInstance*,U32,U32,U32);

void f3753(wasmcomponentldInstance*,U32);

void f3754(wasmcomponentldInstance*,U32);

void f3755(wasmcomponentldInstance*,U32);

void f3756(wasmcomponentldInstance*,U32);

void f3757(wasmcomponentldInstance*,U32);

void f3758(wasmcomponentldInstance*,U32);

void f3759(wasmcomponentldInstance*,U32);

void f3760(wasmcomponentldInstance*,U32);

void f3761(wasmcomponentldInstance*,U32,U32);

U32 f3762(wasmcomponentldInstance*,U32,U32);

U32 f3763(wasmcomponentldInstance*,U32,U32);

U32 f3764(wasmcomponentldInstance*,U32,U32,U32);

void f3765(wasmcomponentldInstance*,U32,U32);

U32 f3766(wasmcomponentldInstance*,U32,U32);

U32 f3767(wasmcomponentldInstance*,U32);

U32 f3768(wasmcomponentldInstance*,U32,U32);

void f3769(wasmcomponentldInstance*,U32,U32);

void f3770(wasmcomponentldInstance*,U32);

void f3771(wasmcomponentldInstance*,U32,U32,U32);

void f3772(wasmcomponentldInstance*,U32,U32);

void f3773(wasmcomponentldInstance*,U32,U32);

void f3774(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f3775(wasmcomponentldInstance*,U32,U32);

void f3776(wasmcomponentldInstance*,U32,U32);

void f3777(wasmcomponentldInstance*,U32,U32);

void f3778(wasmcomponentldInstance*,U32,U32,U32);

void f3779(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f3780(wasmcomponentldInstance*,U32,U32,U32);

void f3781(wasmcomponentldInstance*,U32,U32);

void f3782(wasmcomponentldInstance*,U32,U32);

void f3783(wasmcomponentldInstance*,U32,U32);

void f3784(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3785(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3786(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3787(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3788(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3789(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3790(wasmcomponentldInstance*,U32,U32,U32);

void f3791(wasmcomponentldInstance*,U32,U32);

void f3792(wasmcomponentldInstance*,U32,U32);

void f3793(wasmcomponentldInstance*,U32,U32);

void f3794(wasmcomponentldInstance*,U32,U32);

U32 f3795(wasmcomponentldInstance*,U32,U32,U32);

void f3796(wasmcomponentldInstance*,U32,U32,U32);

U32 f3797(wasmcomponentldInstance*,U32,U32,U32);

void f3798(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3799(wasmcomponentldInstance*,U32,U32);

void f3800(wasmcomponentldInstance*,U32,U32);

void f3801(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f3802(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3803(wasmcomponentldInstance*,U32,U32);

void f3804(wasmcomponentldInstance*,U32,U32,U32);

void f3805(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3806(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3807(wasmcomponentldInstance*,U32,U32,U32);

void f3808(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f3809(wasmcomponentldInstance*,U32,U32);

U32 f3810(wasmcomponentldInstance*,U32,U32);

U32 f3811(wasmcomponentldInstance*,U32,U32);

void f3812(wasmcomponentldInstance*,U32);

void f3813(wasmcomponentldInstance*,U32);

void f3814(wasmcomponentldInstance*,U32);

void f3815(wasmcomponentldInstance*,U32);

void f3816(wasmcomponentldInstance*,U32);

void f3817(wasmcomponentldInstance*,U32);

void f3818(wasmcomponentldInstance*,U32);

void f3819(wasmcomponentldInstance*,U32);

void f3820(wasmcomponentldInstance*,U32);

void f3821(wasmcomponentldInstance*,U32);

void f3822(wasmcomponentldInstance*,U32);

void f3823(wasmcomponentldInstance*,U32);

void f3824(wasmcomponentldInstance*,U32);

void f3825(wasmcomponentldInstance*,U32);

void f3826(wasmcomponentldInstance*,U32);

void f3827(wasmcomponentldInstance*,U32);

void f3828(wasmcomponentldInstance*,U32);

void f3829(wasmcomponentldInstance*,U32);

void f3830(wasmcomponentldInstance*,U32);

void f3831(wasmcomponentldInstance*,U32);

void f3832(wasmcomponentldInstance*,U32);

void f3833(wasmcomponentldInstance*,U32);

void f3834(wasmcomponentldInstance*,U32);

void f3835(wasmcomponentldInstance*,U32);

void f3836(wasmcomponentldInstance*,U32);

void f3837(wasmcomponentldInstance*,U32);

void f3838(wasmcomponentldInstance*,U32);

void f3839(wasmcomponentldInstance*,U32);

void f3840(wasmcomponentldInstance*,U32);

void f3841(wasmcomponentldInstance*,U32);

void f3842(wasmcomponentldInstance*,U32);

void f3843(wasmcomponentldInstance*,U32);

void f3844(wasmcomponentldInstance*,U32);

void f3845(wasmcomponentldInstance*,U32);

void f3846(wasmcomponentldInstance*,U32);

void f3847(wasmcomponentldInstance*,U32);

void f3848(wasmcomponentldInstance*,U32,U32);

void f3849(wasmcomponentldInstance*,U32,U32);

void f3850(wasmcomponentldInstance*,U32,U32);

void f3851(wasmcomponentldInstance*,U32,U32);

void f3852(wasmcomponentldInstance*,U32,U32);

void f3853(wasmcomponentldInstance*,U32,U32);

void f3854(wasmcomponentldInstance*,U32,U32);

void f3855(wasmcomponentldInstance*,U32,U32);

void f3856(wasmcomponentldInstance*,U32,U32);

void f3857(wasmcomponentldInstance*,U32,U32);

void f3858(wasmcomponentldInstance*,U32,U32);

void f3859(wasmcomponentldInstance*,U32,U32);

void f3860(wasmcomponentldInstance*,U32,U32);

void f3861(wasmcomponentldInstance*,U32,U32);

void f3862(wasmcomponentldInstance*,U32,U32);

void f3863(wasmcomponentldInstance*,U32,U32);

void f3864(wasmcomponentldInstance*,U32,U32);

void f3865(wasmcomponentldInstance*,U32,U32);

void f3866(wasmcomponentldInstance*,U32,U32);

void f3867(wasmcomponentldInstance*,U32,U32);

void f3868(wasmcomponentldInstance*,U32,U32);

void f3869(wasmcomponentldInstance*,U32,U32,U32);

void f3870(wasmcomponentldInstance*,U32,U32,U32);

void f3871(wasmcomponentldInstance*,U32,U32,U32);

void f3872(wasmcomponentldInstance*,U32,U32,U32);

void f3873(wasmcomponentldInstance*,U32,U32,U32);

void f3874(wasmcomponentldInstance*,U32,U32);

void f3875(wasmcomponentldInstance*,U32,U32);

void f3876(wasmcomponentldInstance*,U32,U32);

void f3877(wasmcomponentldInstance*,U32,U32);

void f3878(wasmcomponentldInstance*,U32,U32);

void f3879(wasmcomponentldInstance*,U32,U32);

void f3880(wasmcomponentldInstance*,U32,U32);

void f3881(wasmcomponentldInstance*,U32,U32);

void f3882(wasmcomponentldInstance*,U32,U32);

void f3883(wasmcomponentldInstance*,U32,U32);

void f3884(wasmcomponentldInstance*,U32,U32);

void f3885(wasmcomponentldInstance*,U32,U32);

void f3886(wasmcomponentldInstance*,U32,U32);

void f3887(wasmcomponentldInstance*,U32,U32);

void f3888(wasmcomponentldInstance*,U32,U32);

void f3889(wasmcomponentldInstance*,U32,U32);

void f3890(wasmcomponentldInstance*,U32,U32);

void f3891(wasmcomponentldInstance*,U32,U32);

void f3892(wasmcomponentldInstance*,U32,U32);

void f3893(wasmcomponentldInstance*,U32,U32);

void f3894(wasmcomponentldInstance*,U32,U32);

void f3895(wasmcomponentldInstance*,U32,U32);

void f3896(wasmcomponentldInstance*,U32,U32);

void f3897(wasmcomponentldInstance*,U32,U32);

U32 f3898(wasmcomponentldInstance*,U32,U32);

void f3899(wasmcomponentldInstance*,U32,U32,U32);

void f3900(wasmcomponentldInstance*,U32,U32,U32,U32);

void f3901(wasmcomponentldInstance*,U32,U32);

void f3902(wasmcomponentldInstance*,U32,U32);

void f3903(wasmcomponentldInstance*,U32,U32);

void f3904(wasmcomponentldInstance*,U32,U32);

void f3905(wasmcomponentldInstance*,U32,U32);

void f3906(wasmcomponentldInstance*,U32,U32);

void f3907(wasmcomponentldInstance*,U32,U32);

void f3908(wasmcomponentldInstance*,U32,U32);

void f3909(wasmcomponentldInstance*,U32,U32);

void f3910(wasmcomponentldInstance*,U32,U32);

void f3911(wasmcomponentldInstance*,U32,U32);

void f3912(wasmcomponentldInstance*,U32,U32);

void f3913(wasmcomponentldInstance*,U32,U32);

void f3914(wasmcomponentldInstance*,U32,U32);

void f3915(wasmcomponentldInstance*,U32,U32);

void f3916(wasmcomponentldInstance*,U32,U32);

void f3917(wasmcomponentldInstance*,U32,U32);

void f3918(wasmcomponentldInstance*,U32,U32);

void f3919(wasmcomponentldInstance*,U32,U32);

void f3920(wasmcomponentldInstance*,U32,U32);

void f3921(wasmcomponentldInstance*,U32,U32);

void f3922(wasmcomponentldInstance*,U32,U32);

void f3923(wasmcomponentldInstance*,U32,U32);

void f3924(wasmcomponentldInstance*,U32,U32);

void f3925(wasmcomponentldInstance*,U32,U32);

void f3926(wasmcomponentldInstance*,U32,U32);

void f3927(wasmcomponentldInstance*,U32,U32);

void f3928(wasmcomponentldInstance*,U32,U32);

void f3929(wasmcomponentldInstance*,U32,U32);

void f3930(wasmcomponentldInstance*,U32,U32);

void f3931(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f3932(wasmcomponentldInstance*,U32,U32);

U32 f3933(wasmcomponentldInstance*,U32,U32);

U32 f3934(wasmcomponentldInstance*,U32,U32);

U32 f3935(wasmcomponentldInstance*,U32,U32);

void f3936(wasmcomponentldInstance*,U32,U32);

void f3937(wasmcomponentldInstance*,U32,U32);

void f3938(wasmcomponentldInstance*,U32,U32);

void f3939(wasmcomponentldInstance*,U32,U32);

void f3940(wasmcomponentldInstance*,U32,U32);

void f3941(wasmcomponentldInstance*,U32,U32);

void f3942(wasmcomponentldInstance*,U32,U32);

void f3943(wasmcomponentldInstance*,U32,U32);

void f3944(wasmcomponentldInstance*,U32,U32);

void f3945(wasmcomponentldInstance*,U32,U32);

void f3946(wasmcomponentldInstance*,U32,U32);

void f3947(wasmcomponentldInstance*,U32,U32);

void f3948(wasmcomponentldInstance*,U32,U32);

void f3949(wasmcomponentldInstance*,U32,U32);

void f3950(wasmcomponentldInstance*,U32,U32);

void f3951(wasmcomponentldInstance*,U32,U32);

void f3952(wasmcomponentldInstance*,U32,U32);

void f3953(wasmcomponentldInstance*,U32,U32);

void f3954(wasmcomponentldInstance*,U32);

void f3955(wasmcomponentldInstance*,U32);

void f3956(wasmcomponentldInstance*,U32);

void f3957(wasmcomponentldInstance*,U32);

void f3958(wasmcomponentldInstance*,U32);

void f3959(wasmcomponentldInstance*,U32);

void f3960(wasmcomponentldInstance*,U32);

void f3961(wasmcomponentldInstance*,U32);

void f3962(wasmcomponentldInstance*,U32);

void f3963(wasmcomponentldInstance*,U32);

void f3964(wasmcomponentldInstance*,U32);

void f3965(wasmcomponentldInstance*,U32);

void f3966(wasmcomponentldInstance*,U32);

void f3967(wasmcomponentldInstance*,U32);

void f3968(wasmcomponentldInstance*,U32);

void f3969(wasmcomponentldInstance*,U32);

U32 f3970(wasmcomponentldInstance*,U32);

void f3971(wasmcomponentldInstance*,U32,U32);

void f3972(wasmcomponentldInstance*,U32,U32);

void f3973(wasmcomponentldInstance*,U32,U32);

void f3974(wasmcomponentldInstance*,U32,U32);

void f3975(wasmcomponentldInstance*,U32,U32);

void f3976(wasmcomponentldInstance*,U32,U32);

void f3977(wasmcomponentldInstance*,U32,U32);

void f3978(wasmcomponentldInstance*,U32,U32);

void f3979(wasmcomponentldInstance*,U32,U32);

void f3980(wasmcomponentldInstance*,U32,U32);

void f3981(wasmcomponentldInstance*,U32,U32);

void f3982(wasmcomponentldInstance*,U32,U32);

void f3983(wasmcomponentldInstance*,U32,U32);

void f3984(wasmcomponentldInstance*,U32,U32);

void f3985(wasmcomponentldInstance*,U32,U32);

void f3986(wasmcomponentldInstance*,U32,U32);

void f3987(wasmcomponentldInstance*,U32,U32);

void f3988(wasmcomponentldInstance*,U32,U32);

U32 f3989(wasmcomponentldInstance*,U32,U64,U64);

U32 f3990(wasmcomponentldInstance*,U32,U64,U64);

U32 f3991(wasmcomponentldInstance*,U32,U64,U64);

U32 f3992(wasmcomponentldInstance*,U32,U64,U64);

U32 f3993(wasmcomponentldInstance*,U32,U64,U64);

U32 f3994(wasmcomponentldInstance*,U32,U64,U64);

U32 f3995(wasmcomponentldInstance*,U32,U64,U64);

U32 f3996(wasmcomponentldInstance*,U32,U64,U64);

U32 f3997(wasmcomponentldInstance*,U32,U64,U64);

U32 f3998(wasmcomponentldInstance*,U32,U64,U64);

U32 f3999(wasmcomponentldInstance*,U32,U64,U64);

U32 f4000(wasmcomponentldInstance*,U32,U64,U64);

U32 f4001(wasmcomponentldInstance*,U32,U64,U64);

U32 f4002(wasmcomponentldInstance*,U32,U64,U64);

U32 f4003(wasmcomponentldInstance*,U32);

U32 f4004(wasmcomponentldInstance*,U32);

U32 f4005(wasmcomponentldInstance*,U32);

void f4006(wasmcomponentldInstance*,U32,U64,U64);

void f4007(wasmcomponentldInstance*,U32,U64,U64);

void f4008(wasmcomponentldInstance*,U32,U64,U64);

void f4009(wasmcomponentldInstance*,U32,U64,U64);

void f4010(wasmcomponentldInstance*,U32,U64,U64);

void f4011(wasmcomponentldInstance*,U32,U64,U64);

void f4012(wasmcomponentldInstance*,U32,U64,U64);

void f4013(wasmcomponentldInstance*,U32,U64,U64);

void f4014(wasmcomponentldInstance*,U32,U64,U64);

void f4015(wasmcomponentldInstance*,U32,U64,U64);

U32 f4016(wasmcomponentldInstance*,U32,U64,U64);

U32 f4017(wasmcomponentldInstance*,U32,U64,U64);

U32 f4018(wasmcomponentldInstance*,U32,U64,U64);

void f4019(wasmcomponentldInstance*,U32,U64,U64);

void f4020(wasmcomponentldInstance*,U32,U64,U64);

void f4021(wasmcomponentldInstance*,U32,U64,U64);

void f4022(wasmcomponentldInstance*,U32,U32);

void f4023(wasmcomponentldInstance*,U32,U32);

void f4024(wasmcomponentldInstance*,U32,U32);

void f4025(wasmcomponentldInstance*,U32,U32);

void f4026(wasmcomponentldInstance*,U32,U32);

void f4027(wasmcomponentldInstance*,U32,U32);

void f4028(wasmcomponentldInstance*,U32,U32);

void f4029(wasmcomponentldInstance*,U32,U32);

void f4030(wasmcomponentldInstance*,U32,U32);

void f4031(wasmcomponentldInstance*,U32,U32);

void f4032(wasmcomponentldInstance*,U32,U32);

void f4033(wasmcomponentldInstance*,U32,U32);

void f4034(wasmcomponentldInstance*,U32,U32);

void f4035(wasmcomponentldInstance*,U32,U32);

void f4036(wasmcomponentldInstance*,U32,U32);

void f4037(wasmcomponentldInstance*,U32,U32);

void f4038(wasmcomponentldInstance*,U32,U32);

void f4039(wasmcomponentldInstance*,U32,U32);

U32 f4040(wasmcomponentldInstance*,U32,U32);

U32 f4041(wasmcomponentldInstance*,U32,U32);

U32 f4042(wasmcomponentldInstance*,U32,U32);

U32 f4043(wasmcomponentldInstance*,U32,U32,U32);

U32 f4044(wasmcomponentldInstance*,U32);

U32 f4045(wasmcomponentldInstance*,U32,U32);

U32 f4046(wasmcomponentldInstance*,U32,U32);

U32 f4047(wasmcomponentldInstance*,U32,U32,U32);

U32 f4048(wasmcomponentldInstance*,U32,U32);

U32 f4049(wasmcomponentldInstance*,U32,U32);

U32 f4050(wasmcomponentldInstance*,U64,U32);

U32 f4051(wasmcomponentldInstance*,U32,U32);

U32 f4052(wasmcomponentldInstance*,U32,U32);

U32 f4053(wasmcomponentldInstance*,U32,U32);

U32 f4054(wasmcomponentldInstance*,U32,U32);

U32 f4055(wasmcomponentldInstance*,U32,U32);

U32 f4056(wasmcomponentldInstance*,U32,U32);

U32 f4057(wasmcomponentldInstance*,U32);

U32 f4058(wasmcomponentldInstance*,U32);

U32 f4059(wasmcomponentldInstance*,U32);

U32 f4060(wasmcomponentldInstance*,U32);

U32 f4061(wasmcomponentldInstance*,U32);

U32 f4062(wasmcomponentldInstance*,U32);

U32 f4063(wasmcomponentldInstance*,U32);

U32 f4064(wasmcomponentldInstance*,U32);

U32 f4065(wasmcomponentldInstance*,U32);

void f4066(wasmcomponentldInstance*,U32,U32);

void f4067(wasmcomponentldInstance*,U32,U32);

void f4068(wasmcomponentldInstance*,U32,U32);

U32 f4069(wasmcomponentldInstance*,U32,U32);

U32 f4070(wasmcomponentldInstance*,U32,U32);

U32 f4071(wasmcomponentldInstance*,U32,U32);

U32 f4072(wasmcomponentldInstance*,U32,U32);

U32 f4073(wasmcomponentldInstance*,U32,U32);

U32 f4074(wasmcomponentldInstance*,U32,U32);

U32 f4075(wasmcomponentldInstance*,U32,U32);

U32 f4076(wasmcomponentldInstance*,U32,U32);

U32 f4077(wasmcomponentldInstance*,U32,U32);

U32 f4078(wasmcomponentldInstance*,U32,U32);

U32 f4079(wasmcomponentldInstance*,U32,U32);

U32 f4080(wasmcomponentldInstance*,U32,U32);

U32 f4081(wasmcomponentldInstance*,U32,U32);

void f4082(wasmcomponentldInstance*,U32,U32);

void f4083(wasmcomponentldInstance*,U32,U32);

void f4084(wasmcomponentldInstance*,U32,U32);

U32 f4085(wasmcomponentldInstance*,U32,U32);

U32 f4086(wasmcomponentldInstance*,U32,U32);

U32 f4087(wasmcomponentldInstance*,U32,U32);

U32 f4088(wasmcomponentldInstance*,U32,U32);

void f4089(wasmcomponentldInstance*,U32);

void f4090(wasmcomponentldInstance*,U32);

void f4091(wasmcomponentldInstance*,U32);

void f4092(wasmcomponentldInstance*,U32);

void f4093(wasmcomponentldInstance*,U32);

void f4094(wasmcomponentldInstance*,U32);

void f4095(wasmcomponentldInstance*,U32);

void f4096(wasmcomponentldInstance*,U32);

void f4097(wasmcomponentldInstance*,U32);

void f4098(wasmcomponentldInstance*,U32);

void f4099(wasmcomponentldInstance*,U32);

void f4100(wasmcomponentldInstance*,U32);

U32 f4101(wasmcomponentldInstance*,U32,U32);

U32 f4102(wasmcomponentldInstance*,U32,U32);

U32 f4103(wasmcomponentldInstance*,U32,U32);

U32 f4104(wasmcomponentldInstance*,U32,U32);

U32 f4105(wasmcomponentldInstance*,U32,U32);

U32 f4106(wasmcomponentldInstance*,U32,U32);

U32 f4107(wasmcomponentldInstance*,U32,U32);

void f4108(wasmcomponentldInstance*,U32);

void f4109(wasmcomponentldInstance*,U32);

void f4110(wasmcomponentldInstance*,U32);

void f4111(wasmcomponentldInstance*,U32);

void f4112(wasmcomponentldInstance*,U32);

void f4113(wasmcomponentldInstance*,U32);

void f4114(wasmcomponentldInstance*,U32);

void f4115(wasmcomponentldInstance*,U32);

void f4116(wasmcomponentldInstance*,U32);

void f4117(wasmcomponentldInstance*,U32);

void f4118(wasmcomponentldInstance*,U32);

U32 f4119(wasmcomponentldInstance*,U32,U32);

U32 f4120(wasmcomponentldInstance*,U32,U32);

U32 f4121(wasmcomponentldInstance*,U32,U32,U32);

void f4122(wasmcomponentldInstance*,U32,U32);

U32 f4123(wasmcomponentldInstance*,U32);

U32 f4124(wasmcomponentldInstance*,U32,U32);

U32 f4125(wasmcomponentldInstance*,U32);

void f4126(wasmcomponentldInstance*,U32,U32);

void f4127(wasmcomponentldInstance*,U32,U32);

void f4128(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4129(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4130(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4131(wasmcomponentldInstance*,U32,U32,U32);

void f4132(wasmcomponentldInstance*,U32,U32);

void f4133(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4134(wasmcomponentldInstance*,U32,U32);

void f4135(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4136(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4137(wasmcomponentldInstance*,U32,U32,U32);

void f4138(wasmcomponentldInstance*,U32,U32,U32);

U32 f4139(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4140(wasmcomponentldInstance*,U32,U32,U32);

void f4141(wasmcomponentldInstance*,U32,U32,U32);

void f4142(wasmcomponentldInstance*,U32,U32,U32);

void f4143(wasmcomponentldInstance*,U32,U32,U32);

void f4144(wasmcomponentldInstance*,U32,U32,U32);

void f4145(wasmcomponentldInstance*,U32,U32,U32);

U32 f4146(wasmcomponentldInstance*,U32,U32,U32);

void f4147(wasmcomponentldInstance*,U32);

void f4148(wasmcomponentldInstance*,U32,U32);

void f4149(wasmcomponentldInstance*,U32);

void f4150(wasmcomponentldInstance*,U32);

void f4151(wasmcomponentldInstance*,U32);

void f4152(wasmcomponentldInstance*,U32);

void f4153(wasmcomponentldInstance*,U32);

void f4154(wasmcomponentldInstance*,U32);

void f4155(wasmcomponentldInstance*,U32);

void f4156(wasmcomponentldInstance*,U32);

void f4157(wasmcomponentldInstance*,U32,U32,U32);

U32 f4158(wasmcomponentldInstance*,U32,U32,U64);

U32 f4159(wasmcomponentldInstance*,U32,U64,U32);

U32 f4160(wasmcomponentldInstance*,U32,U64,U32);

void f4161(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4162(wasmcomponentldInstance*,U32,U32,U32);

void f4163(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4164(wasmcomponentldInstance*,U32,U32,U32);

void f4165(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4166(wasmcomponentldInstance*,U32,U32,U32);

void f4167(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4168(wasmcomponentldInstance*,U32,U32,U32);

void f4169(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4170(wasmcomponentldInstance*,U32,U32,U32);

void f4171(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4172(wasmcomponentldInstance*,U32,U32,U32);

void f4173(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4174(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4175(wasmcomponentldInstance*,U32,U32,U32);

void f4176(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4177(wasmcomponentldInstance*,U32,U32,U32);

void f4178(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4179(wasmcomponentldInstance*,U32,U32,U32);

void f4180(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4181(wasmcomponentldInstance*,U32,U32,U32);

void f4182(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4183(wasmcomponentldInstance*,U32,U32,U32);

void f4184(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4185(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4186(wasmcomponentldInstance*,U32,U32,U32);

void f4187(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4188(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4189(wasmcomponentldInstance*,U32,U32,U32,U32);

U64 f4190(wasmcomponentldInstance*,U32,U32,U32);

void f4191(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4192(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4193(wasmcomponentldInstance*,U32,U32,U32);

void f4194(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4195(wasmcomponentldInstance*,U32,U32,U32);

void f4196(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4197(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4198(wasmcomponentldInstance*,U32,U32,U32);

void f4199(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4200(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4201(wasmcomponentldInstance*,U32,U32,U32);

void f4202(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4203(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4204(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4205(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4206(wasmcomponentldInstance*,U32,U32,U32);

void f4207(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4208(wasmcomponentldInstance*,U32,U32,U32);

void f4209(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4210(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4211(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4212(wasmcomponentldInstance*,U32,U32,U32);

void f4213(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4214(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4215(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4216(wasmcomponentldInstance*,U32,U32,U32);

void f4217(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4218(wasmcomponentldInstance*,U32,U32,U32);

void f4219(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4220(wasmcomponentldInstance*,U32,U32,U32);

void f4221(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4222(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4223(wasmcomponentldInstance*,U32,U32,U32);

void f4224(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4225(wasmcomponentldInstance*,U32,U32,U32);

void f4226(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4227(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4228(wasmcomponentldInstance*,U32,U32,U32);

void f4229(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4230(wasmcomponentldInstance*,U32,U32,U32);

void f4231(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4232(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f4233(wasmcomponentldInstance*,U32,U32,U32);

void f4234(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4235(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4236(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4237(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4238(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f4239(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f4240(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f4241(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f4242(wasmcomponentldInstance*,U32,U64,U32);

U32 f4243(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f4244(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4245(wasmcomponentldInstance*,U32,U32,U32);

void f4246(wasmcomponentldInstance*,U32,U32,U32);

void f4247(wasmcomponentldInstance*,U32,U32);

void f4248(wasmcomponentldInstance*,U32,U32,U32);

U32 f4249(wasmcomponentldInstance*,U32,U32);

U32 f4250(wasmcomponentldInstance*,U32);

void f4251(wasmcomponentldInstance*,U32);

U32 f4252(wasmcomponentldInstance*,U32,U32);

U32 f4253(wasmcomponentldInstance*,U32,U32);

U32 f4254(wasmcomponentldInstance*,U32,U32,U32);

U32 f4255(wasmcomponentldInstance*,U32,U32);

U32 f4256(wasmcomponentldInstance*,U32,U32);

void f4257(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4258(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4259(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4260(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4261(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4262(wasmcomponentldInstance*,U32,U32,U32);

void f4263(wasmcomponentldInstance*,U32,U32,U32);

void f4264(wasmcomponentldInstance*,U32,U32,U32);

void f4265(wasmcomponentldInstance*,U32,U32,U32);

void f4266(wasmcomponentldInstance*,U32,U32,U32);

void f4267(wasmcomponentldInstance*,U32,U32,U32);

U32 f4268(wasmcomponentldInstance*,U32,U32);

U32 f4269(wasmcomponentldInstance*,U32,U32);

U32 f4270(wasmcomponentldInstance*,U32,U32);

void f4271(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4272(wasmcomponentldInstance*,U32,U32,U32);

void f4273(wasmcomponentldInstance*,U32,U32,U32);

void f4274(wasmcomponentldInstance*,U32,U32,U32);

void f4275(wasmcomponentldInstance*,U32,U32,U32);

U32 f4276(wasmcomponentldInstance*,U32,U32);

U32 f4277(wasmcomponentldInstance*,U32,U32);

U32 f4278(wasmcomponentldInstance*,U32,U32,U32);

U32 f4279(wasmcomponentldInstance*,U32,U32,U32);

U32 f4280(wasmcomponentldInstance*,U32,U32);

U32 f4281(wasmcomponentldInstance*,U32,U32);

U32 f4282(wasmcomponentldInstance*,U32,U32);

U32 f4283(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4284(wasmcomponentldInstance*,U32,U32,U32);

U32 f4285(wasmcomponentldInstance*,U32,U32,U32);

U32 f4286(wasmcomponentldInstance*,U32,U32,U32);

void f4287(wasmcomponentldInstance*,U32,U32,U32);

void f4288(wasmcomponentldInstance*,U32,U32,U32);

void f4289(wasmcomponentldInstance*,U32,U32,U32);

void f4290(wasmcomponentldInstance*,U32,U32,U32);

void f4291(wasmcomponentldInstance*,U32,U32,U32);

void f4292(wasmcomponentldInstance*,U32,U32,U32);

U32 f4293(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4294(wasmcomponentldInstance*,U32,U32,U32);

U32 f4295(wasmcomponentldInstance*,U32,U32,U32);

U32 f4296(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4297(wasmcomponentldInstance*,U32,U32,U32);

U32 f4298(wasmcomponentldInstance*,U32,U32,U32);

U32 f4299(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4300(wasmcomponentldInstance*,U32,U32,U32);

U32 f4301(wasmcomponentldInstance*,U32,U32);

U32 f4302(wasmcomponentldInstance*,U32,U32);

U32 f4303(wasmcomponentldInstance*,U32,U32);

void f4304(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4305(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4306(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4307(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4308(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4309(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4310(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4311(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4312(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4313(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4314(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4315(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4316(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4317(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4318(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4319(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4320(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4321(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4322(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4323(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4324(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4325(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4326(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4327(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4328(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4329(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4330(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4331(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f4332(wasmcomponentldInstance*,U32,U32,U32);

U32 f4333(wasmcomponentldInstance*,U32,U32);

void f4334(wasmcomponentldInstance*,U32);

void f4335(wasmcomponentldInstance*,U32);

void f4336(wasmcomponentldInstance*,U32,U32);

void f4337(wasmcomponentldInstance*,U32,U32);

void f4338(wasmcomponentldInstance*,U32,U32);

void f4339(wasmcomponentldInstance*,U32,U32);

void f4340(wasmcomponentldInstance*,U32,U32);

void f4341(wasmcomponentldInstance*,U32,U32);

void f4342(wasmcomponentldInstance*,U32,U32);

U32 f4343(wasmcomponentldInstance*,U32,U32);

U32 f4344(wasmcomponentldInstance*,U32,U32);

void f4345(wasmcomponentldInstance*,U32,U32);

U32 f4346(wasmcomponentldInstance*,U32,U32);

U32 f4347(wasmcomponentldInstance*,U32,U32);

void f4348(wasmcomponentldInstance*,U32,U32,U32);

void f4349(wasmcomponentldInstance*,U32,U32,U32);

void f4350(wasmcomponentldInstance*,U32,U32,U32);

U32 f4351(wasmcomponentldInstance*,U32,U32);

void f4352(wasmcomponentldInstance*,U32,U32,U32);

U32 f4353(wasmcomponentldInstance*,U32,U32);

U32 f4354(wasmcomponentldInstance*,U32,U32,U32);

void f4355(wasmcomponentldInstance*,U32,U32,U32);

U32 f4356(wasmcomponentldInstance*,U32,U32,U32);

U32 f4357(wasmcomponentldInstance*,U32);

U32 f4358(wasmcomponentldInstance*,U32,U32);

U32 f4359(wasmcomponentldInstance*,U32,U32);

U32 f4360(wasmcomponentldInstance*,U32,U32);

U32 f4361(wasmcomponentldInstance*,U32,U32);

U32 f4362(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4363(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4364(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4365(wasmcomponentldInstance*,U32,U32);

void f4366(wasmcomponentldInstance*,U32,U32,U32);

void f4367(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4368(wasmcomponentldInstance*,U32,U32);

U32 f4369(wasmcomponentldInstance*,U32,U32);

void f4370(wasmcomponentldInstance*,U32,U32,U32);

U32 f4371(wasmcomponentldInstance*,U32,U32);

void f4372(wasmcomponentldInstance*,U32,U32,U32);

U32 f4373(wasmcomponentldInstance*,U32,U32);

void f4374(wasmcomponentldInstance*,U32,U32);

void f4375(wasmcomponentldInstance*,U32,U32,U32);

U32 f4376(wasmcomponentldInstance*,U32,U32);

U32 f4377(wasmcomponentldInstance*,U32,U32);

void f4378(wasmcomponentldInstance*,U32,U32,U32);

void f4379(wasmcomponentldInstance*,U32,U32);

void f4380(wasmcomponentldInstance*,U32,U32,U32);

void f4381(wasmcomponentldInstance*,U32,U32,U32);

U32 f4382(wasmcomponentldInstance*,U32,U32);

void f4383(wasmcomponentldInstance*,U32,U32);

void f4384(wasmcomponentldInstance*,U32,U32);

void f4385(wasmcomponentldInstance*,U32,U32,U32);

void f4386(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4387(wasmcomponentldInstance*,U32,U32,U32);

void f4388(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4389(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4390(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4391(wasmcomponentldInstance*,U32,U32,U32);

void f4392(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4393(wasmcomponentldInstance*,U32,U32,U32);

void f4394(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4395(wasmcomponentldInstance*,U32,U32,U32);

void f4396(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4397(wasmcomponentldInstance*,U32,U32,U32);

void f4398(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4399(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4400(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4401(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4402(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f4403(wasmcomponentldInstance*,U32,U32,U32);

U32 f4404(wasmcomponentldInstance*,U32,U32,U32);

U32 f4405(wasmcomponentldInstance*,U32,U32,U32);

void f4406(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4407(wasmcomponentldInstance*,U32,U32);

U32 f4408(wasmcomponentldInstance*,U32,U32);

U32 f4409(wasmcomponentldInstance*,U32,U32);

U64 f4410(wasmcomponentldInstance*,U32,U32);

void f4411(wasmcomponentldInstance*,U32,U32);

U64 f4412(wasmcomponentldInstance*,U32,U32);

void f4413(wasmcomponentldInstance*,U32,U32,U32);

U64 f4414(wasmcomponentldInstance*,U32,U32);

U64 f4415(wasmcomponentldInstance*,U32,U32);

U64 f4416(wasmcomponentldInstance*,U32,U32);

U64 f4417(wasmcomponentldInstance*,U32,U32);

U64 f4418(wasmcomponentldInstance*,U32,U32);

U64 f4419(wasmcomponentldInstance*,U32,U32);

U64 f4420(wasmcomponentldInstance*,U32,U32);

U64 f4421(wasmcomponentldInstance*,U32,U32);

U64 f4422(wasmcomponentldInstance*,U32,U32,U32);

U64 f4423(wasmcomponentldInstance*,U32,U32);

U64 f4424(wasmcomponentldInstance*,U32,U32);

U64 f4425(wasmcomponentldInstance*,U32,U32);

U64 f4426(wasmcomponentldInstance*,U32,U32);

U32 f4427(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4428(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4429(wasmcomponentldInstance*,U32,U32);

U32 f4430(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4431(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4432(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4433(wasmcomponentldInstance*,U32,U32,U32);

U32 f4434(wasmcomponentldInstance*,U32,U32,U32);

U32 f4435(wasmcomponentldInstance*,U32,U32,U32);

U32 f4436(wasmcomponentldInstance*,U32,U32,U32);

void f4437(wasmcomponentldInstance*,U32,U32,U32);

void f4438(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4439(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4440(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4441(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4442(wasmcomponentldInstance*,U32,U32);

void f4443(wasmcomponentldInstance*,U32,U32);

void f4444(wasmcomponentldInstance*,U32,U32);

void f4445(wasmcomponentldInstance*,U32,U32,U32);

void f4446(wasmcomponentldInstance*,U32,U32,U32);

void f4447(wasmcomponentldInstance*,U32,U32,U32);

void f4448(wasmcomponentldInstance*,U32,U32,U32);

U32 f4449(wasmcomponentldInstance*,U32,U32);

void f4450(wasmcomponentldInstance*,U32,U32,U32);

U32 f4451(wasmcomponentldInstance*,U32,U32);

void f4452(wasmcomponentldInstance*,U32,U32,U32);

void f4453(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4454(wasmcomponentldInstance*,U32,U32,U32);

void f4455(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4456(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4457(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4458(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4459(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4460(wasmcomponentldInstance*,U32,U32);

void f4461(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4462(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4463(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4464(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f4465(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4466(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4467(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4468(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4469(wasmcomponentldInstance*,U32,U32);

U32 f4470(wasmcomponentldInstance*,U32,U32);

U64 f4471(wasmcomponentldInstance*,U32,U32);

void f4472(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4473(wasmcomponentldInstance*,U32,U32,U32);

void f4474(wasmcomponentldInstance*,U32,U32);

void f4475(wasmcomponentldInstance*,U32,U32);

U32 f4476(wasmcomponentldInstance*,U32,U32);

void f4477(wasmcomponentldInstance*,U32,U32,U32);

U32 f4478(wasmcomponentldInstance*,U32,U32,U32);

void f4479(wasmcomponentldInstance*,U32,U32);

void f4480(wasmcomponentldInstance*,U32,U32);

void f4481(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4482(wasmcomponentldInstance*,U32);

void f4483(wasmcomponentldInstance*,U32,U32);

void f4484(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4485(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4486(wasmcomponentldInstance*,U32,U32,U32);

void f4487(wasmcomponentldInstance*,U32,U32);

void f4488(wasmcomponentldInstance*,U32,U32,U32);

void f4489(wasmcomponentldInstance*,U32,U32);

void f4490(wasmcomponentldInstance*,U32,U32);

void f4491(wasmcomponentldInstance*,U32);

U32 f4492(wasmcomponentldInstance*,U32);

void f4493(wasmcomponentldInstance*,U32);

U32 f4494(wasmcomponentldInstance*,U32);

void f4495(wasmcomponentldInstance*,U32,U32);

void f4496(wasmcomponentldInstance*,U32,U32);

U32 f4497(wasmcomponentldInstance*,U32);

U32 f4498(wasmcomponentldInstance*,U32);

void f4499(wasmcomponentldInstance*,U32,U32);

void f4500(wasmcomponentldInstance*,U32,U32);

void f4501(wasmcomponentldInstance*,U32,U32);

void f4502(wasmcomponentldInstance*,U32,U32);

void f4503(wasmcomponentldInstance*,U32,U32);

void f4504(wasmcomponentldInstance*,U32,U32);

void f4505(wasmcomponentldInstance*,U32,U32);

void f4506(wasmcomponentldInstance*,U32,U32);

void f4507(wasmcomponentldInstance*,U32,U32);

void f4508(wasmcomponentldInstance*,U32,U32);

void f4509(wasmcomponentldInstance*,U32,U32);

void f4510(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4511(wasmcomponentldInstance*,U32);

void f4512(wasmcomponentldInstance*,U32,U32,U32,U64,U32);

void f4513(wasmcomponentldInstance*,U32,U32,U32,U64,U32);

void f4514(wasmcomponentldInstance*,U32,U32,U32,U64,U32);

void f4515(wasmcomponentldInstance*,U32,U32,U32,U64,U32);

void f4516(wasmcomponentldInstance*,U32,U32,U32,U64);

U32 f4517(wasmcomponentldInstance*,U32);

void f4518(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4519(wasmcomponentldInstance*,U32,U32,U32);

U32 f4520(wasmcomponentldInstance*,U32,U32,U32);

void f4521(wasmcomponentldInstance*,U32,U32);

void f4522(wasmcomponentldInstance*,U32,U32,U32);

U32 f4523(wasmcomponentldInstance*,U32,U32);

U32 f4524(wasmcomponentldInstance*,U32,U32);

U32 f4525(wasmcomponentldInstance*,U32,U32);

U32 f4526(wasmcomponentldInstance*,U32,U32);

U32 f4527(wasmcomponentldInstance*,U32,U32);

U32 f4528(wasmcomponentldInstance*,U32,U32);

U32 f4529(wasmcomponentldInstance*,U32,U32);

U32 f4530(wasmcomponentldInstance*,U32,U32);

U32 f4531(wasmcomponentldInstance*,U32,U32);

U32 f4532(wasmcomponentldInstance*,U32,U32);

void f4533(wasmcomponentldInstance*,U32,U32);

void f4534(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4535(wasmcomponentldInstance*,U32);

void f4536(wasmcomponentldInstance*,U32);

void f4537(wasmcomponentldInstance*,U32);

void f4538(wasmcomponentldInstance*,U32);

void f4539(wasmcomponentldInstance*,U32);

void f4540(wasmcomponentldInstance*,U32);

void f4541(wasmcomponentldInstance*,U32);

void f4542(wasmcomponentldInstance*,U32,U32);

void f4543(wasmcomponentldInstance*,U32,U32);

U32 f4544(wasmcomponentldInstance*,U32,U32);

U32 f4545(wasmcomponentldInstance*,U32,U32);

U32 f4546(wasmcomponentldInstance*,U32,U32);

U32 f4547(wasmcomponentldInstance*,U32,U32,U32);

void f4548(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4549(wasmcomponentldInstance*,U32,U32,U32);

void f4550(wasmcomponentldInstance*,U32,U32);

void f4551(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4552(wasmcomponentldInstance*,U32,U32);

U32 f4553(wasmcomponentldInstance*,U32,U32);

U32 f4554(wasmcomponentldInstance*,U32,U32);

void f4555(wasmcomponentldInstance*,U32,U32);

void f4556(wasmcomponentldInstance*,U32,U32);

void f4557(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4558(wasmcomponentldInstance*,U32,U32);

void f4559(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4560(wasmcomponentldInstance*,U32,U32);

void f4561(wasmcomponentldInstance*,U32,U32);

void f4562(wasmcomponentldInstance*,U32,U32);

void f4563(wasmcomponentldInstance*,U32,U32);

void f4564(wasmcomponentldInstance*,U32,U32);

void f4565(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4566(wasmcomponentldInstance*,U32,U32);

void f4567(wasmcomponentldInstance*,U32,U32);

U32 f4568(wasmcomponentldInstance*,U32);

void f4569(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4570(wasmcomponentldInstance*,U32,U32);

void f4571(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4572(wasmcomponentldInstance*,U32,U32);

void f4573(wasmcomponentldInstance*,U32,U32);

void f4574(wasmcomponentldInstance*,U32);

void f4575(wasmcomponentldInstance*,U32);

void f4576(wasmcomponentldInstance*,U32,U32);

U32 f4577(wasmcomponentldInstance*,U32,U32);

void f4578(wasmcomponentldInstance*,U32,U32);

void f4579(wasmcomponentldInstance*,U32,U32);

void f4580(wasmcomponentldInstance*,U32,U32);

void f4581(wasmcomponentldInstance*,U32,U32);

void f4582(wasmcomponentldInstance*,U32,U32);

void f4583(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4584(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4585(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4586(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4587(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4588(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4589(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4590(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4591(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4592(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4593(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4594(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4595(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4596(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4597(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4598(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f4599(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4600(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4601(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4602(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4603(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4604(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4605(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4606(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4607(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4608(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4609(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4610(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4611(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f4612(wasmcomponentldInstance*,U32,U32);

void f4613(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4614(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4615(wasmcomponentldInstance*,U32,U32);

void f4616(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4617(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4618(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4619(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4620(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4621(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4622(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4623(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4624(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4625(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4626(wasmcomponentldInstance*,U32,U32);

void f4627(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4628(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4629(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4630(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4631(wasmcomponentldInstance*,U32,U32,U32);

U32 f4632(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4633(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4634(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4635(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4636(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4637(wasmcomponentldInstance*,U32,U32);

void f4638(wasmcomponentldInstance*,U32,U32);

void f4639(wasmcomponentldInstance*,U32,U32);

void f4640(wasmcomponentldInstance*,U32,U32);

void f4641(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4642(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4643(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4644(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4645(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4646(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4647(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4648(wasmcomponentldInstance*,U32,U32,U32);

void f4649(wasmcomponentldInstance*,U32,U32,U32);

void f4650(wasmcomponentldInstance*,U32,U32,U32);

U32 f4651(wasmcomponentldInstance*,U32,U32);

U32 f4652(wasmcomponentldInstance*,U32,U32);

U32 f4653(wasmcomponentldInstance*,U32,U32);

U32 f4654(wasmcomponentldInstance*,U32,U32);

U32 f4655(wasmcomponentldInstance*,U32,U32);

void f4656(wasmcomponentldInstance*,U32);

void f4657(wasmcomponentldInstance*,U32);

void f4658(wasmcomponentldInstance*,U32);

void f4659(wasmcomponentldInstance*,U32);

void f4660(wasmcomponentldInstance*,U32);

void f4661(wasmcomponentldInstance*,U32);

void f4662(wasmcomponentldInstance*,U32);

void f4663(wasmcomponentldInstance*,U32);

void f4664(wasmcomponentldInstance*,U32);

void f4665(wasmcomponentldInstance*,U32);

void f4666(wasmcomponentldInstance*,U32);

void f4667(wasmcomponentldInstance*,U32);

void f4668(wasmcomponentldInstance*,U32);

void f4669(wasmcomponentldInstance*,U32);

void f4670(wasmcomponentldInstance*,U32);

void f4671(wasmcomponentldInstance*,U32);

void f4672(wasmcomponentldInstance*,U32,U32);

U32 f4673(wasmcomponentldInstance*,U32,U32);

U32 f4674(wasmcomponentldInstance*,U32,U32,U32);

U32 f4675(wasmcomponentldInstance*,U32,U32);

U32 f4676(wasmcomponentldInstance*,U32,U32);

U32 f4677(wasmcomponentldInstance*,U32,U32,U32);

void f4678(wasmcomponentldInstance*,U32,U32);

void f4679(wasmcomponentldInstance*,U32,U32);

void f4680(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4681(wasmcomponentldInstance*,U32,U32);

U32 f4682(wasmcomponentldInstance*,U32,U32);

U32 f4683(wasmcomponentldInstance*,U32,U32);

void f4684(wasmcomponentldInstance*,U32,U32,U32);

void f4685(wasmcomponentldInstance*,U32,U32);

void f4686(wasmcomponentldInstance*,U32,U32,U32);

void f4687(wasmcomponentldInstance*,U32,U32,U32);

void f4688(wasmcomponentldInstance*,U32,U32,U32);

void f4689(wasmcomponentldInstance*,U32,U32,U32);

void f4690(wasmcomponentldInstance*,U32,U32,U32);

void f4691(wasmcomponentldInstance*,U32,U32,U32);

void f4692(wasmcomponentldInstance*,U32);

void f4693(wasmcomponentldInstance*,U32);

void f4694(wasmcomponentldInstance*,U32);

void f4695(wasmcomponentldInstance*,U32);

void f4696(wasmcomponentldInstance*,U32);

void f4697(wasmcomponentldInstance*,U32);

void f4698(wasmcomponentldInstance*,U32);

void f4699(wasmcomponentldInstance*,U32);

void f4700(wasmcomponentldInstance*,U32);

void f4701(wasmcomponentldInstance*,U32);

void f4702(wasmcomponentldInstance*,U32);

void f4703(wasmcomponentldInstance*,U32);

void f4704(wasmcomponentldInstance*,U32);

void f4705(wasmcomponentldInstance*,U32);

void f4706(wasmcomponentldInstance*,U32);

void f4707(wasmcomponentldInstance*,U32);

void f4708(wasmcomponentldInstance*,U32);

void f4709(wasmcomponentldInstance*,U32);

void f4710(wasmcomponentldInstance*,U32);

void f4711(wasmcomponentldInstance*,U32);

void f4712(wasmcomponentldInstance*,U32);

void f4713(wasmcomponentldInstance*,U32);

void f4714(wasmcomponentldInstance*,U32);

void f4715(wasmcomponentldInstance*,U32);

void f4716(wasmcomponentldInstance*,U32);

void f4717(wasmcomponentldInstance*,U32);

void f4718(wasmcomponentldInstance*,U32,U32,U32);

void f4719(wasmcomponentldInstance*,U32,U32,U32);

void f4720(wasmcomponentldInstance*,U32,U32,U32);

void f4721(wasmcomponentldInstance*,U32,U32,U32);

void f4722(wasmcomponentldInstance*,U32,U32,U32);

void f4723(wasmcomponentldInstance*,U32,U32,U32);

void f4724(wasmcomponentldInstance*,U32,U32,U32);

void f4725(wasmcomponentldInstance*,U32,U32,U32);

void f4726(wasmcomponentldInstance*,U32,U32,U32);

U32 f4727(wasmcomponentldInstance*,U32,U32);

U32 f4728(wasmcomponentldInstance*,U32,U32);

U32 f4729(wasmcomponentldInstance*,U32,U32);

void f4730(wasmcomponentldInstance*,U32,U32);

void f4731(wasmcomponentldInstance*,U32,U32);

void f4732(wasmcomponentldInstance*,U32,U32);

U32 f4733(wasmcomponentldInstance*,U32,U32);

void f4734(wasmcomponentldInstance*,U32,U32);

U32 f4735(wasmcomponentldInstance*,U32,U32);

void f4736(wasmcomponentldInstance*,U32,U32);

void f4737(wasmcomponentldInstance*,U32,U32);

void f4738(wasmcomponentldInstance*,U32,U32,U32);

void f4739(wasmcomponentldInstance*,U32,U32);

void f4740(wasmcomponentldInstance*,U32,U32);

void f4741(wasmcomponentldInstance*,U32,U32);

void f4742(wasmcomponentldInstance*,U32,U32,U32);

void f4743(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4744(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4745(wasmcomponentldInstance*,U32,U32,U32);

void f4746(wasmcomponentldInstance*,U32,U32);

void f4747(wasmcomponentldInstance*,U32,U32,U32);

void f4748(wasmcomponentldInstance*,U32,U32,U32);

U32 f4749(wasmcomponentldInstance*,U32,U32);

void f4750(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4751(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4752(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4753(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4754(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4755(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4756(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4757(wasmcomponentldInstance*,U32,U32,U32);

void f4758(wasmcomponentldInstance*,U32,U32,U32);

void f4759(wasmcomponentldInstance*,U32,U32,U32);

U32 f4760(wasmcomponentldInstance*,U32,U32);

U32 f4761(wasmcomponentldInstance*,U32);

U32 f4762(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4763(wasmcomponentldInstance*,U32,U32,U32);

U32 f4764(wasmcomponentldInstance*,U32,U32);

U32 f4765(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4766(wasmcomponentldInstance*,U32,U32);

void f4767(wasmcomponentldInstance*,U32,U32);

U32 f4768(wasmcomponentldInstance*,U32,U32);

void f4769(wasmcomponentldInstance*,U32,U32);

void f4770(wasmcomponentldInstance*,U32,U32);

void f4771(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4772(wasmcomponentldInstance*,U32,U32);

U32 f4773(wasmcomponentldInstance*,U32,U32);

U32 f4774(wasmcomponentldInstance*,U32,U32);

void f4775(wasmcomponentldInstance*,U32);

void f4776(wasmcomponentldInstance*,U32,U32,U32);

void f4777(wasmcomponentldInstance*,U32,U32,U32);

void f4778(wasmcomponentldInstance*,U32,U32,U32);

void f4779(wasmcomponentldInstance*,U32,U32);

void f4780(wasmcomponentldInstance*,U32,U32);

void f4781(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4782(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f4783(wasmcomponentldInstance*,U32,U32,U32);

U32 f4784(wasmcomponentldInstance*,U32,U32);

U32 f4785(wasmcomponentldInstance*,U32,U32);

U32 f4786(wasmcomponentldInstance*,U32,U32,U32);

U32 f4787(wasmcomponentldInstance*,U32);

U32 f4788(wasmcomponentldInstance*,U32,U32);

void f4789(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4790(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4791(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4792(wasmcomponentldInstance*,U32,U32,U32);

void f4793(wasmcomponentldInstance*,U32,U32,U32);

void f4794(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4795(wasmcomponentldInstance*,U32,U32,U32);

U32 f4796(wasmcomponentldInstance*,U32,U32);

U32 f4797(wasmcomponentldInstance*,U32,U32);

U32 f4798(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f4799(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f4800(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f4801(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f4802(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f4803(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

void f4804(wasmcomponentldInstance*,U32);

void f4805(wasmcomponentldInstance*,U32);

void f4806(wasmcomponentldInstance*,U32);

void f4807(wasmcomponentldInstance*,U32);

void f4808(wasmcomponentldInstance*,U32);

void f4809(wasmcomponentldInstance*,U32);

void f4810(wasmcomponentldInstance*,U32,U32);

U32 f4811(wasmcomponentldInstance*,U32,U32);

U32 f4812(wasmcomponentldInstance*,U32);

void f4813(wasmcomponentldInstance*,U32,U32,U32);

U32 f4814(wasmcomponentldInstance*,U32,U32);

void f4815(wasmcomponentldInstance*,U32,U32,U32);

void f4816(wasmcomponentldInstance*,U32,U32);

void f4817(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4818(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f4819(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

void f4820(wasmcomponentldInstance*,U32,U32,U32);

U32 f4821(wasmcomponentldInstance*,U32,U32,U32);

void f4822(wasmcomponentldInstance*,U32,U32);

U32 f4823(wasmcomponentldInstance*,U32);

void f4824(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4825(wasmcomponentldInstance*,U32,U32,U32);

void f4826(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4827(wasmcomponentldInstance*,U32,U32);

void f4828(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

void f4829(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4830(wasmcomponentldInstance*,U32,U32,U32);

void f4831(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4832(wasmcomponentldInstance*,U32,U32);

void f4833(wasmcomponentldInstance*,U32,U32,U32);

void f4834(wasmcomponentldInstance*,U32,U32,U32);

void f4835(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4836(wasmcomponentldInstance*,U32,U32);

U32 f4837(wasmcomponentldInstance*,U32,U32);

U32 f4838(wasmcomponentldInstance*,U32,U32);

U32 f4839(wasmcomponentldInstance*,U32,U32);

U32 f4840(wasmcomponentldInstance*,U32,U32);

U32 f4841(wasmcomponentldInstance*,U32,U32);

U32 f4842(wasmcomponentldInstance*,U32,U32);

U32 f4843(wasmcomponentldInstance*,U32,U32);

U32 f4844(wasmcomponentldInstance*,U32,U32);

U32 f4845(wasmcomponentldInstance*,U32,U32);

U32 f4846(wasmcomponentldInstance*,U32,U32);

U32 f4847(wasmcomponentldInstance*,U32,U32);

U32 f4848(wasmcomponentldInstance*,U32,U32);

U32 f4849(wasmcomponentldInstance*,U32,U32);

U32 f4850(wasmcomponentldInstance*,U32,U32);

U32 f4851(wasmcomponentldInstance*,U32,U32);

U32 f4852(wasmcomponentldInstance*,U32,U32);

U32 f4853(wasmcomponentldInstance*,U32,U32);

U32 f4854(wasmcomponentldInstance*,U32,U32);

U32 f4855(wasmcomponentldInstance*,U32,U32);

U32 f4856(wasmcomponentldInstance*,U32,U32);

U32 f4857(wasmcomponentldInstance*,U32,U32);

U32 f4858(wasmcomponentldInstance*,U32,U32);

U32 f4859(wasmcomponentldInstance*,U32,U32);

U32 f4860(wasmcomponentldInstance*,U32,U32);

U32 f4861(wasmcomponentldInstance*,U32,U32);

U32 f4862(wasmcomponentldInstance*,U32,U32);

U32 f4863(wasmcomponentldInstance*,U32,U32);

U32 f4864(wasmcomponentldInstance*,U32,U32);

U32 f4865(wasmcomponentldInstance*,U32,U32);

U32 f4866(wasmcomponentldInstance*,U32,U32);

U32 f4867(wasmcomponentldInstance*,U32,U32);

U32 f4868(wasmcomponentldInstance*,U32,U32);

U32 f4869(wasmcomponentldInstance*,U32,U32);

U32 f4870(wasmcomponentldInstance*,U32,U32);

U32 f4871(wasmcomponentldInstance*,U32,U32);

U32 f4872(wasmcomponentldInstance*,U32,U32);

U32 f4873(wasmcomponentldInstance*,U32,U32);

U32 f4874(wasmcomponentldInstance*,U32,U32);

void f4875(wasmcomponentldInstance*,U32);

void f4876(wasmcomponentldInstance*,U32);

void f4877(wasmcomponentldInstance*,U32);

void f4878(wasmcomponentldInstance*,U32);

void f4879(wasmcomponentldInstance*,U32);

void f4880(wasmcomponentldInstance*,U32);

void f4881(wasmcomponentldInstance*,U32);

void f4882(wasmcomponentldInstance*,U32,U32,U32);

void f4883(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f4884(wasmcomponentldInstance*,U32,U32,U32);

void f4885(wasmcomponentldInstance*,U32,U32);

void f4886(wasmcomponentldInstance*,U32,U32);

void f4887(wasmcomponentldInstance*,U32,U32);

void f4888(wasmcomponentldInstance*,U32,U32);

void f4889(wasmcomponentldInstance*,U32,U32);

void f4890(wasmcomponentldInstance*,U32,U32);

U32 f4891(wasmcomponentldInstance*,U32,U32);

U32 f4892(wasmcomponentldInstance*,U32,U32);

U32 f4893(wasmcomponentldInstance*,U32,U32);

U32 f4894(wasmcomponentldInstance*,U32,U32);

U32 f4895(wasmcomponentldInstance*,U32,U32);

U32 f4896(wasmcomponentldInstance*,U32,U32);

U32 f4897(wasmcomponentldInstance*,U32,U32);

U32 f4898(wasmcomponentldInstance*,U32,U32);

U32 f4899(wasmcomponentldInstance*,U32,U32);

U32 f4900(wasmcomponentldInstance*,U32,U32);

U32 f4901(wasmcomponentldInstance*,U32,U32);

U32 f4902(wasmcomponentldInstance*,U32,U32);

U32 f4903(wasmcomponentldInstance*,U32,U32);

U32 f4904(wasmcomponentldInstance*,U32,U32,U32);

void f4905(wasmcomponentldInstance*,U32,U32);

U32 f4906(wasmcomponentldInstance*,U32,U32);

U32 f4907(wasmcomponentldInstance*,U32,U32);

U32 f4908(wasmcomponentldInstance*,U32,U32);

void f4909(wasmcomponentldInstance*,U32,U32);

void f4910(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4911(wasmcomponentldInstance*,U32,U32);

void f4912(wasmcomponentldInstance*,U32,U32,U32);

void f4913(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4914(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4915(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4916(wasmcomponentldInstance*,U32,U32);

void f4917(wasmcomponentldInstance*,U32,U32);

U32 f4918(wasmcomponentldInstance*,U32);

U32 f4919(wasmcomponentldInstance*,U32);

void f4920(wasmcomponentldInstance*,U32,U32,U32);

void f4921(wasmcomponentldInstance*,U32,U32);

void f4922(wasmcomponentldInstance*,U32,U32);

void f4923(wasmcomponentldInstance*,U32,U32);

void f4924(wasmcomponentldInstance*,U32,U32);

void f4925(wasmcomponentldInstance*,U32,U32);

void f4926(wasmcomponentldInstance*,U32,U32);

U32 f4927(wasmcomponentldInstance*,U32,U32);

U32 f4928(wasmcomponentldInstance*,U32,U32);

void f4929(wasmcomponentldInstance*,U32,U32);

U32 f4930(wasmcomponentldInstance*,U32,U32);

void f4931(wasmcomponentldInstance*,U32,U32);

void f4932(wasmcomponentldInstance*,U32,U32,U32);

void f4933(wasmcomponentldInstance*,U32,U32);

U32 f4934(wasmcomponentldInstance*,U32,U32);

void f4935(wasmcomponentldInstance*,U32,U32);

void f4936(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4937(wasmcomponentldInstance*,U32,U32,U32);

void f4938(wasmcomponentldInstance*,U32,U32,U32);

U32 f4939(wasmcomponentldInstance*,U32,U32);

U32 f4940(wasmcomponentldInstance*,U32,U32);

U32 f4941(wasmcomponentldInstance*,U32,U32);

U32 f4942(wasmcomponentldInstance*,U32,U32);

U32 f4943(wasmcomponentldInstance*,U32,U32);

void f4944(wasmcomponentldInstance*,U32,U32);

void f4945(wasmcomponentldInstance*,U32,U32,U32);

U32 f4946(wasmcomponentldInstance*,U32,U32);

U32 f4947(wasmcomponentldInstance*,U32,U32);

U32 f4948(wasmcomponentldInstance*,U32,U32);

void f4949(wasmcomponentldInstance*,U32);

void f4950(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f4951(wasmcomponentldInstance*,U32,U32);

U32 f4952(wasmcomponentldInstance*,U32,U32);

U32 f4953(wasmcomponentldInstance*,U32,U32);

U32 f4954(wasmcomponentldInstance*,U32,U32,U32);

U32 f4955(wasmcomponentldInstance*,U32,U32,U32);

U32 f4956(wasmcomponentldInstance*,U32,U32);

void f4957(wasmcomponentldInstance*,U32,U32);

U32 f4958(wasmcomponentldInstance*,U32,U32);

U32 f4959(wasmcomponentldInstance*,U32,U32);

U32 f4960(wasmcomponentldInstance*,U32);

U32 f4961(wasmcomponentldInstance*,U32);

U32 f4962(wasmcomponentldInstance*,U32,U32,U32);

U32 f4963(wasmcomponentldInstance*,U32,U32);

U32 f4964(wasmcomponentldInstance*,U32,U32,U32);

U32 f4965(wasmcomponentldInstance*,U32,U32,U32);

U32 f4966(wasmcomponentldInstance*,U32,U32);

U32 f4967(wasmcomponentldInstance*,U32,U32);

U32 f4968(wasmcomponentldInstance*,U32,U32);

void f4969(wasmcomponentldInstance*,U32);

U32 f4970(wasmcomponentldInstance*,U32,U32);

U32 f4971(wasmcomponentldInstance*,U32,U32,U32);

void f4972(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4973(wasmcomponentldInstance*,U32,U32);

void f4974(wasmcomponentldInstance*,U32);

void f4975(wasmcomponentldInstance*,U32,U32);

void f4976(wasmcomponentldInstance*,U32,U32);

void f4977(wasmcomponentldInstance*,U32,U32,U32);

void f4978(wasmcomponentldInstance*,U32,U32,U32);

U32 f4979(wasmcomponentldInstance*,U32,U32,U32);

void f4980(wasmcomponentldInstance*,U32,U32,U32);

U32 f4981(wasmcomponentldInstance*,U32);

U32 f4982(wasmcomponentldInstance*,U32,U32);

void f4983(wasmcomponentldInstance*,U32,U32,U32);

void f4984(wasmcomponentldInstance*,U32,U32,U32);

U32 f4985(wasmcomponentldInstance*,U32,U32,U32);

void f4986(wasmcomponentldInstance*,U32,U32,U32,U32);

void f4987(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f4988(wasmcomponentldInstance*,F64,U32);

U32 f4989(wasmcomponentldInstance*,U32,U32);

void f4990(wasmcomponentldInstance*,U32,U32);

void f4991(wasmcomponentldInstance*,U32);

void f4992(wasmcomponentldInstance*,U32,U32);

U32 f4993(wasmcomponentldInstance*,U32);

U32 f4994(wasmcomponentldInstance*,U32);

U32 f4995(wasmcomponentldInstance*,U32);

U32 f4996(wasmcomponentldInstance*,U32);

U32 f4997(wasmcomponentldInstance*,U32);

U32 f4998(wasmcomponentldInstance*,U32,U32);

U32 f4999(wasmcomponentldInstance*,U32,U32);

U32 f5000(wasmcomponentldInstance*,U32,U32);

U32 f5001(wasmcomponentldInstance*,U32);

U32 f5002(wasmcomponentldInstance*,U32);

U32 f5003(wasmcomponentldInstance*,U32,U32);

U32 f5004(wasmcomponentldInstance*,U32,U32);

U32 f5005(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5006(wasmcomponentldInstance*,U32,U32);

U32 f5007(wasmcomponentldInstance*,U32,U32);

U32 f5008(wasmcomponentldInstance*,U32);

U32 f5009(wasmcomponentldInstance*,U32,U32);

U32 f5010(wasmcomponentldInstance*,U32,U32);

U32 f5011(wasmcomponentldInstance*,U32,U32,U32);

U32 f5012(wasmcomponentldInstance*,U32,U32);

U32 f5013(wasmcomponentldInstance*,U32,U32);

U32 f5014(wasmcomponentldInstance*,U32,U32,U32);

U32 f5015(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5016(wasmcomponentldInstance*,U32,U32);

U32 f5017(wasmcomponentldInstance*,U32);

U32 f5018(wasmcomponentldInstance*,U32,U32);

U32 f5019(wasmcomponentldInstance*,U32,U32);

U32 f5020(wasmcomponentldInstance*,U32,U32);

U32 f5021(wasmcomponentldInstance*,U32);

U32 f5022(wasmcomponentldInstance*,U32,U32);

U32 f5023(wasmcomponentldInstance*,U32);

U32 f5024(wasmcomponentldInstance*,U32);

U32 f5025(wasmcomponentldInstance*,U32,U32);

U32 f5026(wasmcomponentldInstance*,U32,U32);

U32 f5027(wasmcomponentldInstance*,U32,U32);

U32 f5028(wasmcomponentldInstance*,U32,U32);

U32 f5029(wasmcomponentldInstance*,U32,U32);

U32 f5030(wasmcomponentldInstance*,U32,U32);

U32 f5031(wasmcomponentldInstance*,U32,U32);

U32 f5032(wasmcomponentldInstance*,U32,U32);

U32 f5033(wasmcomponentldInstance*,U32,U32);

U32 f5034(wasmcomponentldInstance*,U32,U32);

U32 f5035(wasmcomponentldInstance*,U32,U32);

U32 f5036(wasmcomponentldInstance*,U32,U32);

U32 f5037(wasmcomponentldInstance*,U32,U32);

U32 f5038(wasmcomponentldInstance*,U32,U32);

U32 f5039(wasmcomponentldInstance*,U32,U32);

U32 f5040(wasmcomponentldInstance*,U32,U32);

U32 f5041(wasmcomponentldInstance*,U32,U32);

U32 f5042(wasmcomponentldInstance*,U32,U32);

U32 f5043(wasmcomponentldInstance*,U32,U32);

U32 f5044(wasmcomponentldInstance*,U32,U32);

U32 f5045(wasmcomponentldInstance*,U32,U32);

U32 f5046(wasmcomponentldInstance*,U32,U32);

U32 f5047(wasmcomponentldInstance*,U32,U32);

U32 f5048(wasmcomponentldInstance*,U32,U32);

U32 f5049(wasmcomponentldInstance*,U32,U32);

U32 f5050(wasmcomponentldInstance*,U32,U32);

U32 f5051(wasmcomponentldInstance*,U32,U32);

U32 f5052(wasmcomponentldInstance*,U32,U32);

U32 f5053(wasmcomponentldInstance*,U32,U32);

U32 f5054(wasmcomponentldInstance*,U32,U32);

U32 f5055(wasmcomponentldInstance*,U32,U32,U32);

U32 f5056(wasmcomponentldInstance*,U32,U32);

U32 f5057(wasmcomponentldInstance*,U32,U32,U32);

U32 f5058(wasmcomponentldInstance*,U32,U32);

U32 f5059(wasmcomponentldInstance*,U32,U32);

U32 f5060(wasmcomponentldInstance*,U32,U32);

U32 f5061(wasmcomponentldInstance*,U32,U64);

U32 f5062(wasmcomponentldInstance*,U32,U32);

U32 f5063(wasmcomponentldInstance*,U32,U64);

U32 f5064(wasmcomponentldInstance*,U32);

U32 f5065(wasmcomponentldInstance*,U32);

U32 f5066(wasmcomponentldInstance*,U32);

U32 f5067(wasmcomponentldInstance*,U32);

U32 f5068(wasmcomponentldInstance*,U32);

U32 f5069(wasmcomponentldInstance*,U32);

U32 f5070(wasmcomponentldInstance*,U32);

U32 f5071(wasmcomponentldInstance*,U32);

U32 f5072(wasmcomponentldInstance*,U32);

U32 f5073(wasmcomponentldInstance*,U32);

U32 f5074(wasmcomponentldInstance*,U32);

U32 f5075(wasmcomponentldInstance*,U32);

U32 f5076(wasmcomponentldInstance*,U32);

U32 f5077(wasmcomponentldInstance*,U32);

U32 f5078(wasmcomponentldInstance*,U32);

U32 f5079(wasmcomponentldInstance*,U32);

U32 f5080(wasmcomponentldInstance*,U32);

U32 f5081(wasmcomponentldInstance*,U32);

U32 f5082(wasmcomponentldInstance*,U32);

U32 f5083(wasmcomponentldInstance*,U32);

U32 f5084(wasmcomponentldInstance*,U32);

U32 f5085(wasmcomponentldInstance*,U32);

U32 f5086(wasmcomponentldInstance*,U32);

U32 f5087(wasmcomponentldInstance*,U32);

U32 f5088(wasmcomponentldInstance*,U32);

U32 f5089(wasmcomponentldInstance*,U32);

U32 f5090(wasmcomponentldInstance*,U32);

U32 f5091(wasmcomponentldInstance*,U32);

U32 f5092(wasmcomponentldInstance*,U32);

U32 f5093(wasmcomponentldInstance*,U32);

U32 f5094(wasmcomponentldInstance*,U32);

U32 f5095(wasmcomponentldInstance*,U32);

U32 f5096(wasmcomponentldInstance*,U32);

U32 f5097(wasmcomponentldInstance*,U32);

U32 f5098(wasmcomponentldInstance*,U32);

U32 f5099(wasmcomponentldInstance*,U32);

U32 f5100(wasmcomponentldInstance*,U32);

U32 f5101(wasmcomponentldInstance*,U32);

U32 f5102(wasmcomponentldInstance*,U32);

U32 f5103(wasmcomponentldInstance*,U32);

U32 f5104(wasmcomponentldInstance*,U32);

U32 f5105(wasmcomponentldInstance*,U32);

U32 f5106(wasmcomponentldInstance*,U32);

U32 f5107(wasmcomponentldInstance*,U32);

U32 f5108(wasmcomponentldInstance*,U32);

U32 f5109(wasmcomponentldInstance*,U32);

U32 f5110(wasmcomponentldInstance*,U32);

U32 f5111(wasmcomponentldInstance*,U32);

U32 f5112(wasmcomponentldInstance*,U32);

U32 f5113(wasmcomponentldInstance*,U32);

U32 f5114(wasmcomponentldInstance*,U32);

U32 f5115(wasmcomponentldInstance*,U32);

U32 f5116(wasmcomponentldInstance*,U32);

U32 f5117(wasmcomponentldInstance*,U32);

U32 f5118(wasmcomponentldInstance*,U32);

U32 f5119(wasmcomponentldInstance*,U32);

U32 f5120(wasmcomponentldInstance*,U32);

U32 f5121(wasmcomponentldInstance*,U32);

U32 f5122(wasmcomponentldInstance*,U32);

U32 f5123(wasmcomponentldInstance*,U32);

U32 f5124(wasmcomponentldInstance*,U32);

U32 f5125(wasmcomponentldInstance*,U32);

U32 f5126(wasmcomponentldInstance*,U32);

U32 f5127(wasmcomponentldInstance*,U32);

U32 f5128(wasmcomponentldInstance*,U32);

U32 f5129(wasmcomponentldInstance*,U32);

U32 f5130(wasmcomponentldInstance*,U32);

U32 f5131(wasmcomponentldInstance*,U32);

U32 f5132(wasmcomponentldInstance*,U32);

U32 f5133(wasmcomponentldInstance*,U32);

U32 f5134(wasmcomponentldInstance*,U32);

U32 f5135(wasmcomponentldInstance*,U32);

U32 f5136(wasmcomponentldInstance*,U32);

U32 f5137(wasmcomponentldInstance*,U32);

U32 f5138(wasmcomponentldInstance*,U32);

U32 f5139(wasmcomponentldInstance*,U32);

U32 f5140(wasmcomponentldInstance*,U32);

U32 f5141(wasmcomponentldInstance*,U32);

U32 f5142(wasmcomponentldInstance*,U32);

U32 f5143(wasmcomponentldInstance*,U32);

U32 f5144(wasmcomponentldInstance*,U32);

U32 f5145(wasmcomponentldInstance*,U32);

U32 f5146(wasmcomponentldInstance*,U32);

U32 f5147(wasmcomponentldInstance*,U32);

U32 f5148(wasmcomponentldInstance*,U32);

U32 f5149(wasmcomponentldInstance*,U32);

U32 f5150(wasmcomponentldInstance*,U32);

U32 f5151(wasmcomponentldInstance*,U32);

U32 f5152(wasmcomponentldInstance*,U32);

U32 f5153(wasmcomponentldInstance*,U32);

U32 f5154(wasmcomponentldInstance*,U32);

U32 f5155(wasmcomponentldInstance*,U32);

U32 f5156(wasmcomponentldInstance*,U32);

U32 f5157(wasmcomponentldInstance*,U32);

U32 f5158(wasmcomponentldInstance*,U32);

U32 f5159(wasmcomponentldInstance*,U32);

U32 f5160(wasmcomponentldInstance*,U32);

U32 f5161(wasmcomponentldInstance*,U32);

U32 f5162(wasmcomponentldInstance*,U32);

U32 f5163(wasmcomponentldInstance*,U32);

U32 f5164(wasmcomponentldInstance*,U32);

U32 f5165(wasmcomponentldInstance*,U32);

U32 f5166(wasmcomponentldInstance*,U32);

U32 f5167(wasmcomponentldInstance*,U32);

U32 f5168(wasmcomponentldInstance*,U32);

U32 f5169(wasmcomponentldInstance*,U32);

U32 f5170(wasmcomponentldInstance*,U32);

U32 f5171(wasmcomponentldInstance*,U32);

U32 f5172(wasmcomponentldInstance*,U32);

U32 f5173(wasmcomponentldInstance*,U32);

U32 f5174(wasmcomponentldInstance*,U32);

U32 f5175(wasmcomponentldInstance*,U32);

U32 f5176(wasmcomponentldInstance*,U32);

U32 f5177(wasmcomponentldInstance*,U32);

U32 f5178(wasmcomponentldInstance*,U32);

U32 f5179(wasmcomponentldInstance*,U32);

U32 f5180(wasmcomponentldInstance*,U32);

U32 f5181(wasmcomponentldInstance*,U32);

U32 f5182(wasmcomponentldInstance*,U32);

U32 f5183(wasmcomponentldInstance*,U32);

U32 f5184(wasmcomponentldInstance*,U32);

U32 f5185(wasmcomponentldInstance*,U32);

U32 f5186(wasmcomponentldInstance*,U32);

U32 f5187(wasmcomponentldInstance*,U32);

U32 f5188(wasmcomponentldInstance*,U32);

U32 f5189(wasmcomponentldInstance*,U32);

U32 f5190(wasmcomponentldInstance*,U32);

U32 f5191(wasmcomponentldInstance*,U32);

U32 f5192(wasmcomponentldInstance*,U32);

U32 f5193(wasmcomponentldInstance*,U32);

U32 f5194(wasmcomponentldInstance*,U32);

U32 f5195(wasmcomponentldInstance*,U32);

U32 f5196(wasmcomponentldInstance*,U32);

U32 f5197(wasmcomponentldInstance*,U32);

U32 f5198(wasmcomponentldInstance*,U32);

U32 f5199(wasmcomponentldInstance*,U32);

U32 f5200(wasmcomponentldInstance*,U32,U32);

U32 f5201(wasmcomponentldInstance*,U32,U32,U32);

U32 f5202(wasmcomponentldInstance*,U32,U32);

U32 f5203(wasmcomponentldInstance*,U32);

U32 f5204(wasmcomponentldInstance*,U32,U32);

U32 f5205(wasmcomponentldInstance*,U32);

U32 f5206(wasmcomponentldInstance*,U32);

U32 f5207(wasmcomponentldInstance*,U32,U32);

U32 f5208(wasmcomponentldInstance*,U32,U32);

U32 f5209(wasmcomponentldInstance*,U32,U32,U32);

U32 f5210(wasmcomponentldInstance*,U32,U32,U32);

U32 f5211(wasmcomponentldInstance*,U32,U32,U32);

U32 f5212(wasmcomponentldInstance*,U32,U32,U32);

U32 f5213(wasmcomponentldInstance*,U32,U32);

U32 f5214(wasmcomponentldInstance*,U32,U32);

U32 f5215(wasmcomponentldInstance*,U32,U32);

U32 f5216(wasmcomponentldInstance*,U32,U32);

U32 f5217(wasmcomponentldInstance*,U32,U32,U32);

U32 f5218(wasmcomponentldInstance*,U32,U32,U32);

U32 f5219(wasmcomponentldInstance*,U32,U32,U32);

U32 f5220(wasmcomponentldInstance*,U32,U32);

U32 f5221(wasmcomponentldInstance*,U32,U32);

U32 f5222(wasmcomponentldInstance*,U32,U32);

U32 f5223(wasmcomponentldInstance*,U32,U32);

U32 f5224(wasmcomponentldInstance*,U32);

U32 f5225(wasmcomponentldInstance*,U32,U32);

U32 f5226(wasmcomponentldInstance*,U32,U32,U32);

U32 f5227(wasmcomponentldInstance*,U32,U32,U32);

U32 f5228(wasmcomponentldInstance*,U32,U32,U32);

U32 f5229(wasmcomponentldInstance*,U32,U32);

U32 f5230(wasmcomponentldInstance*,U32,U32);

U32 f5231(wasmcomponentldInstance*,U32,U32);

U32 f5232(wasmcomponentldInstance*,U32,U32);

U32 f5233(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5234(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5235(wasmcomponentldInstance*,U32);

U32 f5236(wasmcomponentldInstance*,U32);

U32 f5237(wasmcomponentldInstance*,U32);

U32 f5238(wasmcomponentldInstance*,U32);

U32 f5239(wasmcomponentldInstance*,U32);

U32 f5240(wasmcomponentldInstance*,U32,U32,U32);

U32 f5241(wasmcomponentldInstance*,U32,U32);

U32 f5242(wasmcomponentldInstance*,U32,U32);

U32 f5243(wasmcomponentldInstance*,U32,U32);

U32 f5244(wasmcomponentldInstance*,U32,U32);

U32 f5245(wasmcomponentldInstance*,U32,U32);

U32 f5246(wasmcomponentldInstance*,U32,U32);

U32 f5247(wasmcomponentldInstance*,U32,U32,U32);

U32 f5248(wasmcomponentldInstance*,U32,U32);

U32 f5249(wasmcomponentldInstance*,U32,U32);

U32 f5250(wasmcomponentldInstance*,U32,U32);

U32 f5251(wasmcomponentldInstance*,U32,U32);

U32 f5252(wasmcomponentldInstance*,U32,U32);

U32 f5253(wasmcomponentldInstance*,U32,U32);

U32 f5254(wasmcomponentldInstance*,U32,U32);

U32 f5255(wasmcomponentldInstance*,U32,U32);

U32 f5256(wasmcomponentldInstance*,U32,U32);

U32 f5257(wasmcomponentldInstance*,U32,U32);

U32 f5258(wasmcomponentldInstance*,U32,U32);

U32 f5259(wasmcomponentldInstance*,U32,U32);

U32 f5260(wasmcomponentldInstance*,U32,U32);

U32 f5261(wasmcomponentldInstance*,U32,U32);

U32 f5262(wasmcomponentldInstance*,U32,U32,U32);

U32 f5263(wasmcomponentldInstance*,U32,U32,U32);

U32 f5264(wasmcomponentldInstance*,U32,U32,U32);

U32 f5265(wasmcomponentldInstance*,U32,U32,U32);

U32 f5266(wasmcomponentldInstance*,U32,U32,U32);

U32 f5267(wasmcomponentldInstance*,U32,U32,U32);

U32 f5268(wasmcomponentldInstance*,U32,U32,U32);

U32 f5269(wasmcomponentldInstance*,U32,U32,U32);

U32 f5270(wasmcomponentldInstance*,U32,U64,U64);

U32 f5271(wasmcomponentldInstance*,U32,U32);

U32 f5272(wasmcomponentldInstance*,U32,U32);

U32 f5273(wasmcomponentldInstance*,U32,U32);

U32 f5274(wasmcomponentldInstance*,U32,U32);

U32 f5275(wasmcomponentldInstance*,U32,U32);

U32 f5276(wasmcomponentldInstance*,U32,U32);

U32 f5277(wasmcomponentldInstance*,U32,U32);

U32 f5278(wasmcomponentldInstance*,U32,U32);

U32 f5279(wasmcomponentldInstance*,U32,U32);

U32 f5280(wasmcomponentldInstance*,U32,U32);

U32 f5281(wasmcomponentldInstance*,U32,U32);

U32 f5282(wasmcomponentldInstance*,U32,U32);

U32 f5283(wasmcomponentldInstance*,U32,U32);

U32 f5284(wasmcomponentldInstance*,U32,U32);

U32 f5285(wasmcomponentldInstance*,U32,U32);

U32 f5286(wasmcomponentldInstance*,U32);

U32 f5287(wasmcomponentldInstance*,U32);

U32 f5288(wasmcomponentldInstance*,U32);

U32 f5289(wasmcomponentldInstance*,U32);

U32 f5290(wasmcomponentldInstance*,U32);

U32 f5291(wasmcomponentldInstance*,U32);

U32 f5292(wasmcomponentldInstance*,U32);

U32 f5293(wasmcomponentldInstance*,U32);

U32 f5294(wasmcomponentldInstance*,U32);

U32 f5295(wasmcomponentldInstance*,U32);

U32 f5296(wasmcomponentldInstance*,U32);

U32 f5297(wasmcomponentldInstance*,U32);

U32 f5298(wasmcomponentldInstance*,U32);

U32 f5299(wasmcomponentldInstance*,U32);

U32 f5300(wasmcomponentldInstance*,U32);

U32 f5301(wasmcomponentldInstance*,U32);

U32 f5302(wasmcomponentldInstance*,U32);

U32 f5303(wasmcomponentldInstance*,U32);

U32 f5304(wasmcomponentldInstance*,U32);

U32 f5305(wasmcomponentldInstance*,U32);

U32 f5306(wasmcomponentldInstance*,U32);

U32 f5307(wasmcomponentldInstance*,U32);

U32 f5308(wasmcomponentldInstance*,U32);

U32 f5309(wasmcomponentldInstance*,U32);

U32 f5310(wasmcomponentldInstance*,U32);

U32 f5311(wasmcomponentldInstance*,U32);

U32 f5312(wasmcomponentldInstance*,U32);

U32 f5313(wasmcomponentldInstance*,U32);

U32 f5314(wasmcomponentldInstance*,U32);

U32 f5315(wasmcomponentldInstance*,U32);

U32 f5316(wasmcomponentldInstance*,U32);

U32 f5317(wasmcomponentldInstance*,U32);

U32 f5318(wasmcomponentldInstance*,U32);

U32 f5319(wasmcomponentldInstance*,U32);

U32 f5320(wasmcomponentldInstance*,U32);

U32 f5321(wasmcomponentldInstance*,U32);

U32 f5322(wasmcomponentldInstance*,U32);

U32 f5323(wasmcomponentldInstance*,U32);

U32 f5324(wasmcomponentldInstance*,U32);

U32 f5325(wasmcomponentldInstance*,U32);

U32 f5326(wasmcomponentldInstance*,U32);

U32 f5327(wasmcomponentldInstance*,U32);

U32 f5328(wasmcomponentldInstance*,U32);

U32 f5329(wasmcomponentldInstance*,U32);

U32 f5330(wasmcomponentldInstance*,U32);

U32 f5331(wasmcomponentldInstance*,U32);

U32 f5332(wasmcomponentldInstance*,U32);

U32 f5333(wasmcomponentldInstance*,U32);

U32 f5334(wasmcomponentldInstance*,U32);

U32 f5335(wasmcomponentldInstance*,U32);

U32 f5336(wasmcomponentldInstance*,U32);

U32 f5337(wasmcomponentldInstance*,U32);

U32 f5338(wasmcomponentldInstance*,U32);

U32 f5339(wasmcomponentldInstance*,U32);

U32 f5340(wasmcomponentldInstance*,U32);

U32 f5341(wasmcomponentldInstance*,U32);

U32 f5342(wasmcomponentldInstance*,U32);

U32 f5343(wasmcomponentldInstance*,U32);

U32 f5344(wasmcomponentldInstance*,U32);

U32 f5345(wasmcomponentldInstance*,U32);

U32 f5346(wasmcomponentldInstance*,U32);

U32 f5347(wasmcomponentldInstance*,U32);

U32 f5348(wasmcomponentldInstance*,U32);

U32 f5349(wasmcomponentldInstance*,U32);

U32 f5350(wasmcomponentldInstance*,U32);

U32 f5351(wasmcomponentldInstance*,U32);

U32 f5352(wasmcomponentldInstance*,U32);

U32 f5353(wasmcomponentldInstance*,U32);

U32 f5354(wasmcomponentldInstance*,U32);

U32 f5355(wasmcomponentldInstance*,U32);

U32 f5356(wasmcomponentldInstance*,U32);

U32 f5357(wasmcomponentldInstance*,U32);

U32 f5358(wasmcomponentldInstance*,U32);

U32 f5359(wasmcomponentldInstance*,U32);

U32 f5360(wasmcomponentldInstance*,U32);

U32 f5361(wasmcomponentldInstance*,U32);

U32 f5362(wasmcomponentldInstance*,U32);

U32 f5363(wasmcomponentldInstance*,U32);

U32 f5364(wasmcomponentldInstance*,U32);

U32 f5365(wasmcomponentldInstance*,U32);

U32 f5366(wasmcomponentldInstance*,U32);

U32 f5367(wasmcomponentldInstance*,U32);

U32 f5368(wasmcomponentldInstance*,U32);

U32 f5369(wasmcomponentldInstance*,U32);

U32 f5370(wasmcomponentldInstance*,U32);

U32 f5371(wasmcomponentldInstance*,U32);

U32 f5372(wasmcomponentldInstance*,U32);

U32 f5373(wasmcomponentldInstance*,U32);

U32 f5374(wasmcomponentldInstance*,U32);

U32 f5375(wasmcomponentldInstance*,U32);

U32 f5376(wasmcomponentldInstance*,U32);

U32 f5377(wasmcomponentldInstance*,U32);

U32 f5378(wasmcomponentldInstance*,U32);

U32 f5379(wasmcomponentldInstance*,U32);

U32 f5380(wasmcomponentldInstance*,U32);

U32 f5381(wasmcomponentldInstance*,U32);

U32 f5382(wasmcomponentldInstance*,U32);

U32 f5383(wasmcomponentldInstance*,U32);

U32 f5384(wasmcomponentldInstance*,U32);

U32 f5385(wasmcomponentldInstance*,U32);

U32 f5386(wasmcomponentldInstance*,U32);

U32 f5387(wasmcomponentldInstance*,U32);

U32 f5388(wasmcomponentldInstance*,U32);

U32 f5389(wasmcomponentldInstance*,U32);

U32 f5390(wasmcomponentldInstance*,U32);

U32 f5391(wasmcomponentldInstance*,U32);

U32 f5392(wasmcomponentldInstance*,U32);

U32 f5393(wasmcomponentldInstance*,U32);

U32 f5394(wasmcomponentldInstance*,U32);

U32 f5395(wasmcomponentldInstance*,U32);

U32 f5396(wasmcomponentldInstance*,U32);

U32 f5397(wasmcomponentldInstance*,U32);

U32 f5398(wasmcomponentldInstance*,U32);

U32 f5399(wasmcomponentldInstance*,U32);

U32 f5400(wasmcomponentldInstance*,U32);

U32 f5401(wasmcomponentldInstance*,U32);

U32 f5402(wasmcomponentldInstance*,U32);

U32 f5403(wasmcomponentldInstance*,U32);

U32 f5404(wasmcomponentldInstance*,U32);

U32 f5405(wasmcomponentldInstance*,U32);

U32 f5406(wasmcomponentldInstance*,U32);

U32 f5407(wasmcomponentldInstance*,U32);

U32 f5408(wasmcomponentldInstance*,U32);

U32 f5409(wasmcomponentldInstance*,U32);

U32 f5410(wasmcomponentldInstance*,U32);

U32 f5411(wasmcomponentldInstance*,U32);

U32 f5412(wasmcomponentldInstance*,U32);

U32 f5413(wasmcomponentldInstance*,U32);

U32 f5414(wasmcomponentldInstance*,U32);

U32 f5415(wasmcomponentldInstance*,U32);

U32 f5416(wasmcomponentldInstance*,U32);

U32 f5417(wasmcomponentldInstance*,U32);

U32 f5418(wasmcomponentldInstance*,U32);

U32 f5419(wasmcomponentldInstance*,U32);

U32 f5420(wasmcomponentldInstance*,U32);

U32 f5421(wasmcomponentldInstance*,U32);

U32 f5422(wasmcomponentldInstance*,U32);

U32 f5423(wasmcomponentldInstance*,U32);

U32 f5424(wasmcomponentldInstance*,U32);

U32 f5425(wasmcomponentldInstance*,U32);

U32 f5426(wasmcomponentldInstance*,U32);

U32 f5427(wasmcomponentldInstance*,U32);

U32 f5428(wasmcomponentldInstance*,U32);

U32 f5429(wasmcomponentldInstance*,U32);

U32 f5430(wasmcomponentldInstance*,U32);

U32 f5431(wasmcomponentldInstance*,U32);

U32 f5432(wasmcomponentldInstance*,U32);

U32 f5433(wasmcomponentldInstance*,U32);

U32 f5434(wasmcomponentldInstance*,U32);

U32 f5435(wasmcomponentldInstance*,U32);

U32 f5436(wasmcomponentldInstance*,U32);

U32 f5437(wasmcomponentldInstance*,U32);

U32 f5438(wasmcomponentldInstance*,U32);

U32 f5439(wasmcomponentldInstance*,U32);

U32 f5440(wasmcomponentldInstance*,U32);

U32 f5441(wasmcomponentldInstance*,U32);

U32 f5442(wasmcomponentldInstance*,U32);

U32 f5443(wasmcomponentldInstance*,U32);

U32 f5444(wasmcomponentldInstance*,U32);

U32 f5445(wasmcomponentldInstance*,U32);

U32 f5446(wasmcomponentldInstance*,U32);

U32 f5447(wasmcomponentldInstance*,U32);

U32 f5448(wasmcomponentldInstance*,U32);

U32 f5449(wasmcomponentldInstance*,U32);

U32 f5450(wasmcomponentldInstance*,U32);

U32 f5451(wasmcomponentldInstance*,U32);

U32 f5452(wasmcomponentldInstance*,U32);

U32 f5453(wasmcomponentldInstance*,U32);

U32 f5454(wasmcomponentldInstance*,U32);

U32 f5455(wasmcomponentldInstance*,U32);

U32 f5456(wasmcomponentldInstance*,U32);

U32 f5457(wasmcomponentldInstance*,U32);

U32 f5458(wasmcomponentldInstance*,U32);

U32 f5459(wasmcomponentldInstance*,U32);

U32 f5460(wasmcomponentldInstance*,U32);

U32 f5461(wasmcomponentldInstance*,U32);

U32 f5462(wasmcomponentldInstance*,U32);

U32 f5463(wasmcomponentldInstance*,U32);

U32 f5464(wasmcomponentldInstance*,U32);

U32 f5465(wasmcomponentldInstance*,U32);

U32 f5466(wasmcomponentldInstance*,U32);

U32 f5467(wasmcomponentldInstance*,U32);

U32 f5468(wasmcomponentldInstance*,U32);

U32 f5469(wasmcomponentldInstance*,U32);

U32 f5470(wasmcomponentldInstance*,U32);

U32 f5471(wasmcomponentldInstance*,U32);

U32 f5472(wasmcomponentldInstance*,U32);

U32 f5473(wasmcomponentldInstance*,U32);

U32 f5474(wasmcomponentldInstance*,U32);

U32 f5475(wasmcomponentldInstance*,U32);

U32 f5476(wasmcomponentldInstance*,U32);

U32 f5477(wasmcomponentldInstance*,U32);

U32 f5478(wasmcomponentldInstance*,U32);

U32 f5479(wasmcomponentldInstance*,U32);

U32 f5480(wasmcomponentldInstance*,U32);

U32 f5481(wasmcomponentldInstance*,U32);

U32 f5482(wasmcomponentldInstance*,U32);

U32 f5483(wasmcomponentldInstance*,U32);

U32 f5484(wasmcomponentldInstance*,U32);

U32 f5485(wasmcomponentldInstance*,U32);

U32 f5486(wasmcomponentldInstance*,U32);

U32 f5487(wasmcomponentldInstance*,U32);

U32 f5488(wasmcomponentldInstance*,U32);

U32 f5489(wasmcomponentldInstance*,U32);

U32 f5490(wasmcomponentldInstance*,U32);

U32 f5491(wasmcomponentldInstance*,U32);

U32 f5492(wasmcomponentldInstance*,U32);

U32 f5493(wasmcomponentldInstance*,U32);

U32 f5494(wasmcomponentldInstance*,U32);

U32 f5495(wasmcomponentldInstance*,U32);

U32 f5496(wasmcomponentldInstance*,U32);

U32 f5497(wasmcomponentldInstance*,U32);

U32 f5498(wasmcomponentldInstance*,U32);

U32 f5499(wasmcomponentldInstance*,U32);

U32 f5500(wasmcomponentldInstance*,U32);

U32 f5501(wasmcomponentldInstance*,U32);

U32 f5502(wasmcomponentldInstance*,U32);

U32 f5503(wasmcomponentldInstance*,U32);

U32 f5504(wasmcomponentldInstance*,U32,U32);

U32 f5505(wasmcomponentldInstance*,U32,U32);

U32 f5506(wasmcomponentldInstance*,U32,U32);

U32 f5507(wasmcomponentldInstance*,U32);

U32 f5508(wasmcomponentldInstance*,U32,U32);

U32 f5509(wasmcomponentldInstance*,U32,U32);

U32 f5510(wasmcomponentldInstance*,U32,U32);

U32 f5511(wasmcomponentldInstance*,U32,U32);

U32 f5512(wasmcomponentldInstance*,U32,U32);

U32 f5513(wasmcomponentldInstance*,U32,U32);

U32 f5514(wasmcomponentldInstance*,U32,U32);

U32 f5515(wasmcomponentldInstance*,U32,U32);

U32 f5516(wasmcomponentldInstance*,U32,U32);

U32 f5517(wasmcomponentldInstance*,U32,U32);

U32 f5518(wasmcomponentldInstance*,U32,U32);

U32 f5519(wasmcomponentldInstance*,U32,U32);

U32 f5520(wasmcomponentldInstance*,U32,U32);

U32 f5521(wasmcomponentldInstance*,U32,U32);

U32 f5522(wasmcomponentldInstance*,U32,U32);

U32 f5523(wasmcomponentldInstance*,U32,U32);

U32 f5524(wasmcomponentldInstance*,U32,U32);

U32 f5525(wasmcomponentldInstance*,U32,U32);

U32 f5526(wasmcomponentldInstance*,U32,U32);

U32 f5527(wasmcomponentldInstance*,U32,U32);

U32 f5528(wasmcomponentldInstance*,U32,U32);

U32 f5529(wasmcomponentldInstance*,U32,U32);

U32 f5530(wasmcomponentldInstance*,U32,U32);

U32 f5531(wasmcomponentldInstance*,U32,U32);

U32 f5532(wasmcomponentldInstance*,U32,U32);

U32 f5533(wasmcomponentldInstance*,U32,U32);

U32 f5534(wasmcomponentldInstance*,U32,U32);

U32 f5535(wasmcomponentldInstance*,U32,U32);

U32 f5536(wasmcomponentldInstance*,U32,U32);

U32 f5537(wasmcomponentldInstance*,U32,U32);

U32 f5538(wasmcomponentldInstance*,U32,U32);

U32 f5539(wasmcomponentldInstance*,U32,U32);

U32 f5540(wasmcomponentldInstance*,U32,U32);

U32 f5541(wasmcomponentldInstance*,U32,U32);

U32 f5542(wasmcomponentldInstance*,U32,U32);

U32 f5543(wasmcomponentldInstance*,U32,U32);

U32 f5544(wasmcomponentldInstance*,U32,U32);

U32 f5545(wasmcomponentldInstance*,U32,U32);

U32 f5546(wasmcomponentldInstance*,U32,U32);

U32 f5547(wasmcomponentldInstance*,U32,U32);

U32 f5548(wasmcomponentldInstance*,U32,U32);

U32 f5549(wasmcomponentldInstance*,U32,U32);

U32 f5550(wasmcomponentldInstance*,U32,U32);

U32 f5551(wasmcomponentldInstance*,U32,U32);

U32 f5552(wasmcomponentldInstance*,U32,U32);

U32 f5553(wasmcomponentldInstance*,U32,U32);

U32 f5554(wasmcomponentldInstance*,U32,U32);

U32 f5555(wasmcomponentldInstance*,U32,U32);

U32 f5556(wasmcomponentldInstance*,U32,U32);

U32 f5557(wasmcomponentldInstance*,U32,U32);

U32 f5558(wasmcomponentldInstance*,U32,U32);

U32 f5559(wasmcomponentldInstance*,U32,U32);

U32 f5560(wasmcomponentldInstance*,U32,U32);

U32 f5561(wasmcomponentldInstance*,U32,U32);

U32 f5562(wasmcomponentldInstance*,U32,U32);

U32 f5563(wasmcomponentldInstance*,U32,U32);

U32 f5564(wasmcomponentldInstance*,U32,U32);

U32 f5565(wasmcomponentldInstance*,U32,U32);

U32 f5566(wasmcomponentldInstance*,U32,U32);

U32 f5567(wasmcomponentldInstance*,U32,U32);

U32 f5568(wasmcomponentldInstance*,U32,U32);

U32 f5569(wasmcomponentldInstance*,U32,U32);

U32 f5570(wasmcomponentldInstance*,U32,U32);

U32 f5571(wasmcomponentldInstance*,U32,U32,U32);

U32 f5572(wasmcomponentldInstance*,U32,U32,U32);

U32 f5573(wasmcomponentldInstance*,U32,U32,U32);

U32 f5574(wasmcomponentldInstance*,U32,U32,U32);

U32 f5575(wasmcomponentldInstance*,U32,U32,U32);

U32 f5576(wasmcomponentldInstance*,U32,U32,U32);

U32 f5577(wasmcomponentldInstance*,U32,U32,U32);

U32 f5578(wasmcomponentldInstance*,U32,U32,U32);

U32 f5579(wasmcomponentldInstance*,U32,U32,U32);

U32 f5580(wasmcomponentldInstance*,U32,U32,U32);

U32 f5581(wasmcomponentldInstance*,U32,U32,U32);

U32 f5582(wasmcomponentldInstance*,U32,U32,U32);

U32 f5583(wasmcomponentldInstance*,U32,U32,U32);

U32 f5584(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5585(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5586(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5587(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5588(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5589(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5590(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5591(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5592(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5593(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5594(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5595(wasmcomponentldInstance*,U32,U32,U32);

U32 f5596(wasmcomponentldInstance*,U32,U32,U32);

U32 f5597(wasmcomponentldInstance*,U32,U32,U32);

U32 f5598(wasmcomponentldInstance*,U32,U32,U32);

U32 f5599(wasmcomponentldInstance*,U32,U32,U32);

U32 f5600(wasmcomponentldInstance*,U32,U32,U32);

U32 f5601(wasmcomponentldInstance*,U32,U32,U32);

U32 f5602(wasmcomponentldInstance*,U32,U32,U32);

U32 f5603(wasmcomponentldInstance*,U32,U32,U32);

U32 f5604(wasmcomponentldInstance*,U32,U32,U32);

U32 f5605(wasmcomponentldInstance*,U32,U32,U32);

U32 f5606(wasmcomponentldInstance*,U32);

U32 f5607(wasmcomponentldInstance*,U32,U32);

U32 f5608(wasmcomponentldInstance*,U32,U32,U32);

U32 f5609(wasmcomponentldInstance*,U32,U32);

U32 f5610(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5611(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f5612(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5613(wasmcomponentldInstance*,U32,U32,U32);

U32 f5614(wasmcomponentldInstance*,U32);

U32 f5615(wasmcomponentldInstance*,U32);

U32 f5616(wasmcomponentldInstance*,U32);

U32 f5617(wasmcomponentldInstance*,U32);

U32 f5618(wasmcomponentldInstance*,U32,U32);

U32 f5619(wasmcomponentldInstance*,U32,U32);

U32 f5620(wasmcomponentldInstance*,U32,U32);

U32 f5621(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5622(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5623(wasmcomponentldInstance*,U32,U32);

void f5624(wasmcomponentldInstance*,U32,U32);

U32 f5625(wasmcomponentldInstance*,U32,U32);

void f5626(wasmcomponentldInstance*,U32,U32);

void f5627(wasmcomponentldInstance*,U32,U32);

void f5628(wasmcomponentldInstance*,U32,U32);

void f5629(wasmcomponentldInstance*,U32,U32);

void f5630(wasmcomponentldInstance*,U32,U32);

void f5631(wasmcomponentldInstance*,U32,U32);

void f5632(wasmcomponentldInstance*,U32,U32);

void f5633(wasmcomponentldInstance*,U32,U32);

U32 f5634(wasmcomponentldInstance*,U32,U32);

U32 f5635(wasmcomponentldInstance*,U32,U32);

U32 f5636(wasmcomponentldInstance*,U32,U32);

U32 f5637(wasmcomponentldInstance*,U32,U32);

U32 f5638(wasmcomponentldInstance*,U32,U32);

U32 f5639(wasmcomponentldInstance*,U32,U32,U32);

U32 f5640(wasmcomponentldInstance*,U32);

U32 f5641(wasmcomponentldInstance*,U32);

U32 f5642(wasmcomponentldInstance*,U32);

U32 f5643(wasmcomponentldInstance*,U32);

U32 f5644(wasmcomponentldInstance*,U32,U32);

U32 f5645(wasmcomponentldInstance*,U32,U32);

U32 f5646(wasmcomponentldInstance*,U32,U32);

U32 f5647(wasmcomponentldInstance*,U32);

U32 f5648(wasmcomponentldInstance*,U32,U32);

U32 f5649(wasmcomponentldInstance*,U32,U32);

U32 f5650(wasmcomponentldInstance*,U32,U32,U32);

U32 f5651(wasmcomponentldInstance*,U32,U32,U32);

U32 f5652(wasmcomponentldInstance*,U32,U32);

U32 f5653(wasmcomponentldInstance*,U32,U32);

U32 f5654(wasmcomponentldInstance*,U32,U32);

U32 f5655(wasmcomponentldInstance*,U32,U32,U32);

U32 f5656(wasmcomponentldInstance*,U32,U32,U32);

U32 f5657(wasmcomponentldInstance*,U32,U32);

U32 f5658(wasmcomponentldInstance*,U32,U32);

U32 f5659(wasmcomponentldInstance*,U32);

U32 f5660(wasmcomponentldInstance*,U32);

U32 f5661(wasmcomponentldInstance*,U32,U32,U32);

U32 f5662(wasmcomponentldInstance*,U32,U32,U32);

U32 f5663(wasmcomponentldInstance*,U32);

U32 f5664(wasmcomponentldInstance*,U32);

U32 f5665(wasmcomponentldInstance*,U32);

U32 f5666(wasmcomponentldInstance*,U32,U32,U32);

U32 f5667(wasmcomponentldInstance*,U32,U32);

U32 f5668(wasmcomponentldInstance*,U32,U32);

U32 f5669(wasmcomponentldInstance*,U32,U32);

U32 f5670(wasmcomponentldInstance*,U32);

U32 f5671(wasmcomponentldInstance*,U32,U32);

void f5672(wasmcomponentldInstance*,U32,U32);

void f5673(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5674(wasmcomponentldInstance*,U32,U32);

void f5675(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f5676(wasmcomponentldInstance*,U32,U32);

void f5677(wasmcomponentldInstance*,U32,U32);

void f5678(wasmcomponentldInstance*,U32,U32);

void f5679(wasmcomponentldInstance*,U32,U32,U32);

void f5680(wasmcomponentldInstance*,U32,U32,U32);

void f5681(wasmcomponentldInstance*,U32,U32,U32);

void f5682(wasmcomponentldInstance*,U32,U32);

void f5683(wasmcomponentldInstance*,U32,U32,U32);

void f5684(wasmcomponentldInstance*,U32,U32,U32);

void f5685(wasmcomponentldInstance*,U32,U32,U32);

void f5686(wasmcomponentldInstance*,U32,U32);

void f5687(wasmcomponentldInstance*,U32,U32);

void f5688(wasmcomponentldInstance*,U32,U32,U32);

void f5689(wasmcomponentldInstance*,U32,U32,U32);

void f5690(wasmcomponentldInstance*,U32,U32,U32);

void f5691(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5692(wasmcomponentldInstance*,U32);

void f5693(wasmcomponentldInstance*,U32);

void f5694(wasmcomponentldInstance*,U32,U32);

U32 f5695(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5696(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f5697(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f5698(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5699(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f5700(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5701(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f5702(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5703(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5704(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5705(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5706(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5707(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f5708(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5709(wasmcomponentldInstance*,U32,U32);

U32 f5710(wasmcomponentldInstance*,U32,U32);

U32 f5711(wasmcomponentldInstance*,U32,U32);

U32 f5712(wasmcomponentldInstance*,U32);

U32 f5713(wasmcomponentldInstance*,U32);

U32 f5714(wasmcomponentldInstance*,U32);

U32 f5715(wasmcomponentldInstance*,U32,U32);

U32 f5716(wasmcomponentldInstance*,U32,U32);

U32 f5717(wasmcomponentldInstance*,U32,U32);

U32 f5718(wasmcomponentldInstance*,U32);

U32 f5719(wasmcomponentldInstance*,U32,U32);

U32 f5720(wasmcomponentldInstance*,U32,U32);

U32 f5721(wasmcomponentldInstance*,U32,U32,U32);

U32 f5722(wasmcomponentldInstance*,U32,U32,U32);

U32 f5723(wasmcomponentldInstance*,U32,U32);

U32 f5724(wasmcomponentldInstance*,U32,U32);

U32 f5725(wasmcomponentldInstance*,U32,U32);

U32 f5726(wasmcomponentldInstance*,U32,U32,U32);

U32 f5727(wasmcomponentldInstance*,U32,U32,U32);

U32 f5728(wasmcomponentldInstance*,U32,U32);

U32 f5729(wasmcomponentldInstance*,U32,U32);

U32 f5730(wasmcomponentldInstance*,U32);

U32 f5731(wasmcomponentldInstance*,U32);

U32 f5732(wasmcomponentldInstance*,U32,U32,U32);

U32 f5733(wasmcomponentldInstance*,U32,U32,U32);

U32 f5734(wasmcomponentldInstance*,U32);

U32 f5735(wasmcomponentldInstance*,U32);

U32 f5736(wasmcomponentldInstance*,U32);

U32 f5737(wasmcomponentldInstance*,U32,U32,U32);

U32 f5738(wasmcomponentldInstance*,U32,U32);

U32 f5739(wasmcomponentldInstance*,U32,U32);

U32 f5740(wasmcomponentldInstance*,U32,U32);

U32 f5741(wasmcomponentldInstance*,U32);

U32 f5742(wasmcomponentldInstance*,U32,U32);

void f5743(wasmcomponentldInstance*,U32,U32);

void f5744(wasmcomponentldInstance*,U32,U32,U32);

U32 f5745(wasmcomponentldInstance*,U32,U32,U32);

void f5746(wasmcomponentldInstance*,U32,U32);

void f5747(wasmcomponentldInstance*,U32,U32);

U32 f5748(wasmcomponentldInstance*,U32,U32);

void f5749(wasmcomponentldInstance*,U32,U32);

U32 f5750(wasmcomponentldInstance*,U32);

U32 f5751(wasmcomponentldInstance*,U32);

U32 f5752(wasmcomponentldInstance*,U32);

void f5753(wasmcomponentldInstance*,U32,U32);

U32 f5754(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f5755(wasmcomponentldInstance*,U32,U32,U32);

void f5756(wasmcomponentldInstance*,U32);

void f5757(wasmcomponentldInstance*,U32,U32);

U32 f5758(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f5759(wasmcomponentldInstance*,U32,U32);

void f5760(wasmcomponentldInstance*,U32,U32);

U32 f5761(wasmcomponentldInstance*,U32,U32);

void f5762(wasmcomponentldInstance*,U32);

void f5763(wasmcomponentldInstance*,U32);

void f5764(wasmcomponentldInstance*,U32,U32,U32);

void f5765(wasmcomponentldInstance*,U32,U32);

void f5766(wasmcomponentldInstance*,U32,U32,U32);

void f5767(wasmcomponentldInstance*,U32,U32);

void f5768(wasmcomponentldInstance*,U32,U32);

void f5769(wasmcomponentldInstance*,U32,U32);

void f5770(wasmcomponentldInstance*,U32,U32);

void f5771(wasmcomponentldInstance*,U32,U32);

void f5772(wasmcomponentldInstance*,U32,U32);

void f5773(wasmcomponentldInstance*,U32,U32);

void f5774(wasmcomponentldInstance*,U32,U32);

void f5775(wasmcomponentldInstance*,U32,U32,U32);

void f5776(wasmcomponentldInstance*,U32,U32);

void f5777(wasmcomponentldInstance*,U32,U32);

void f5778(wasmcomponentldInstance*,U32,U32);

void f5779(wasmcomponentldInstance*,U32,U32);

void f5780(wasmcomponentldInstance*,U32,U32);

void f5781(wasmcomponentldInstance*,U32,U32);

void f5782(wasmcomponentldInstance*,U32,U32,U32);

void f5783(wasmcomponentldInstance*,U32,U32);

void f5784(wasmcomponentldInstance*,U32,U32);

void f5785(wasmcomponentldInstance*,U32,U32);

void f5786(wasmcomponentldInstance*,U32,U32);

void f5787(wasmcomponentldInstance*,U32,U32);

void f5788(wasmcomponentldInstance*,U32,U32);

void f5789(wasmcomponentldInstance*,U32,U32);

void f5790(wasmcomponentldInstance*,U32,U32);

void f5791(wasmcomponentldInstance*,U32,U32);

void f5792(wasmcomponentldInstance*,U32,U32);

void f5793(wasmcomponentldInstance*,U32,U32);

void f5794(wasmcomponentldInstance*,U32,U32);

void f5795(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5796(wasmcomponentldInstance*,U32,U32,U32);

void f5797(wasmcomponentldInstance*,U32,U32);

U32 f5798(wasmcomponentldInstance*,U32,U32);

U32 f5799(wasmcomponentldInstance*,U32,U32,U32);

void f5800(wasmcomponentldInstance*,U32,U32);

void f5801(wasmcomponentldInstance*,U32,U32);

void f5802(wasmcomponentldInstance*,U32,U32);

void f5803(wasmcomponentldInstance*,U32,U32);

void f5804(wasmcomponentldInstance*,U32,U32);

void f5805(wasmcomponentldInstance*,U32,U32);

void f5806(wasmcomponentldInstance*,U32,U32);

void f5807(wasmcomponentldInstance*,U32,U32);

U32 f5808(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5809(wasmcomponentldInstance*,U32,U32);

U32 f5810(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f5811(wasmcomponentldInstance*,U32,U32);

void f5812(wasmcomponentldInstance*,U32,U32);

U32 f5813(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5814(wasmcomponentldInstance*,U32,U32);

void f5815(wasmcomponentldInstance*,U32,U32);

U32 f5816(wasmcomponentldInstance*,U32,U32);

void f5817(wasmcomponentldInstance*,U32,U32);

U32 f5818(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f5819(wasmcomponentldInstance*,U32,U32);

U32 f5820(wasmcomponentldInstance*,U32,U32,U32);

U32 f5821(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5822(wasmcomponentldInstance*,U32,U32);

U32 f5823(wasmcomponentldInstance*,U32);

U32 f5824(wasmcomponentldInstance*,U32);

U32 f5825(wasmcomponentldInstance*,U32,U32);

U32 f5826(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5827(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5828(wasmcomponentldInstance*,U32);

U32 f5829(wasmcomponentldInstance*,U32);

U32 f5830(wasmcomponentldInstance*,U32,U32);

U32 f5831(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5832(wasmcomponentldInstance*,U32,U32);

U32 f5833(wasmcomponentldInstance*,U32,U32);

void f5834(wasmcomponentldInstance*,U32,U32);

void f5835(wasmcomponentldInstance*,U32,U32);

void f5836(wasmcomponentldInstance*,U32,U32);

void f5837(wasmcomponentldInstance*,U32,U32,U32,U32);

void f5838(wasmcomponentldInstance*,U32,U32);

void f5839(wasmcomponentldInstance*,U32,U32);

void f5840(wasmcomponentldInstance*,U32,U32,U32);

void f5841(wasmcomponentldInstance*,U32,U32);

void f5842(wasmcomponentldInstance*,U32,U32);

void f5843(wasmcomponentldInstance*,U32,U32);

void f5844(wasmcomponentldInstance*,U32,U32);

U32 f5845(wasmcomponentldInstance*,U32,U32);

U32 f5846(wasmcomponentldInstance*,U32,U32);

U32 f5847(wasmcomponentldInstance*,U32,U32,U32);

void f5848(wasmcomponentldInstance*,U32,U32);

U32 f5849(wasmcomponentldInstance*,U32,U32);

U32 f5850(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f5851(wasmcomponentldInstance*,U32,U32);

U32 f5852(wasmcomponentldInstance*,U32,U32);

U32 f5853(wasmcomponentldInstance*,U32,U32);

U32 f5854(wasmcomponentldInstance*,U32,U32,U32);

void f5855(wasmcomponentldInstance*,U32,U32);

void f5856(wasmcomponentldInstance*,U32,U32);

void f5857(wasmcomponentldInstance*,U32,U32);

void f5858(wasmcomponentldInstance*,U32,U64);

void f5859(wasmcomponentldInstance*,U32,U32);

void f5860(wasmcomponentldInstance*,U32,U64);

U32 f5861(wasmcomponentldInstance*,U32,U32);

U32 f5862(wasmcomponentldInstance*,U32,U32);

void f5863(wasmcomponentldInstance*,U32);

U32 f5864(wasmcomponentldInstance*,U32,U32);

U32 f5865(wasmcomponentldInstance*,U32,U32);

U32 f5866(wasmcomponentldInstance*,U32,U32);

U32 f5867(wasmcomponentldInstance*,U32);

U32 f5868(wasmcomponentldInstance*,U32);

U32 f5869(wasmcomponentldInstance*,U32,U32);

U32 f5870(wasmcomponentldInstance*,U32,U32);

U32 f5871(wasmcomponentldInstance*,U32,U32);

U32 f5872(wasmcomponentldInstance*,U32);

U32 f5873(wasmcomponentldInstance*,U32,U32);

U32 f5874(wasmcomponentldInstance*,U32,U32,U32);

U32 f5875(wasmcomponentldInstance*,U32);

U32 f5876(wasmcomponentldInstance*,U32);

U32 f5877(wasmcomponentldInstance*,U32,U32);

U32 f5878(wasmcomponentldInstance*,U32,U32);

U32 f5879(wasmcomponentldInstance*,U32,U32);

U32 f5880(wasmcomponentldInstance*,U32,U32);

U32 f5881(wasmcomponentldInstance*,U32,U32);

U32 f5882(wasmcomponentldInstance*,U32,U32);

U32 f5883(wasmcomponentldInstance*,U32,U32);

U32 f5884(wasmcomponentldInstance*,U32,U32);

U32 f5885(wasmcomponentldInstance*,U32,U32);

U32 f5886(wasmcomponentldInstance*,U32,U32);

U32 f5887(wasmcomponentldInstance*,U32,U32);

U32 f5888(wasmcomponentldInstance*,U32,U32);

U32 f5889(wasmcomponentldInstance*,U32,U32);

U32 f5890(wasmcomponentldInstance*,U32,U32);

U32 f5891(wasmcomponentldInstance*,U32,U32);

U32 f5892(wasmcomponentldInstance*,U32,U32);

U32 f5893(wasmcomponentldInstance*,U32,U32);

U32 f5894(wasmcomponentldInstance*,U32,U32);

U32 f5895(wasmcomponentldInstance*,U32,U64);

U32 f5896(wasmcomponentldInstance*,U32,U32);

U32 f5897(wasmcomponentldInstance*,U32,U64);

U32 f5898(wasmcomponentldInstance*,U32);

U32 f5899(wasmcomponentldInstance*,U32,U32);

U32 f5900(wasmcomponentldInstance*,U32);

U32 f5901(wasmcomponentldInstance*,U32);

U32 f5902(wasmcomponentldInstance*,U32);

U32 f5903(wasmcomponentldInstance*,U32,U32,U32);

U32 f5904(wasmcomponentldInstance*,U32,U32,U32);

U32 f5905(wasmcomponentldInstance*,U32);

U32 f5906(wasmcomponentldInstance*,U32);

U32 f5907(wasmcomponentldInstance*,U32);

U32 f5908(wasmcomponentldInstance*,U32);

U32 f5909(wasmcomponentldInstance*,U32,U32,U32);

U32 f5910(wasmcomponentldInstance*,U32);

U32 f5911(wasmcomponentldInstance*,U32);

U32 f5912(wasmcomponentldInstance*,U32);

U32 f5913(wasmcomponentldInstance*,U32);

U32 f5914(wasmcomponentldInstance*,U32);

U32 f5915(wasmcomponentldInstance*,U32);

U32 f5916(wasmcomponentldInstance*,U32);

U32 f5917(wasmcomponentldInstance*,U32);

U32 f5918(wasmcomponentldInstance*,U32);

U32 f5919(wasmcomponentldInstance*,U32,U32);

U32 f5920(wasmcomponentldInstance*,U32,U32);

U32 f5921(wasmcomponentldInstance*,U32,U32,U32);

U32 f5922(wasmcomponentldInstance*,U32,U32,U32);

U32 f5923(wasmcomponentldInstance*,U32,U32,U32);

U32 f5924(wasmcomponentldInstance*,U32,U32,U32);

U32 f5925(wasmcomponentldInstance*,U32,U32);

U32 f5926(wasmcomponentldInstance*,U32,U32);

U32 f5927(wasmcomponentldInstance*,U32,U32,U32);

U32 f5928(wasmcomponentldInstance*,U32,U32,U32);

U32 f5929(wasmcomponentldInstance*,U32,U32,U32);

U32 f5930(wasmcomponentldInstance*,U32,U32);

U32 f5931(wasmcomponentldInstance*,U32,U32);

U32 f5932(wasmcomponentldInstance*,U32,U32);

U32 f5933(wasmcomponentldInstance*,U32,U32);

U32 f5934(wasmcomponentldInstance*,U32);

U32 f5935(wasmcomponentldInstance*,U32,U32);

U32 f5936(wasmcomponentldInstance*,U32,U32,U32);

U32 f5937(wasmcomponentldInstance*,U32,U32,U32);

U32 f5938(wasmcomponentldInstance*,U32,U32,U32);

U32 f5939(wasmcomponentldInstance*,U32,U32);

U32 f5940(wasmcomponentldInstance*,U32,U32);

U32 f5941(wasmcomponentldInstance*,U32,U32);

U32 f5942(wasmcomponentldInstance*,U32,U32);

U32 f5943(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5944(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5945(wasmcomponentldInstance*,U32);

U32 f5946(wasmcomponentldInstance*,U32);

U32 f5947(wasmcomponentldInstance*,U32);

U32 f5948(wasmcomponentldInstance*,U32);

U32 f5949(wasmcomponentldInstance*,U32,U32);

U32 f5950(wasmcomponentldInstance*,U32,U32);

U32 f5951(wasmcomponentldInstance*,U32,U32);

U32 f5952(wasmcomponentldInstance*,U32,U32);

U32 f5953(wasmcomponentldInstance*,U32,U32);

U32 f5954(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5955(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f5956(wasmcomponentldInstance*,U32);

U32 f5957(wasmcomponentldInstance*,U32);

U32 f5958(wasmcomponentldInstance*,U32);

U32 f5959(wasmcomponentldInstance*,U32);

U32 f5960(wasmcomponentldInstance*,U32,U32,U32);

U32 f5961(wasmcomponentldInstance*,U32,U32);

U32 f5962(wasmcomponentldInstance*,U32,U32,U32);

U32 f5963(wasmcomponentldInstance*,U32,U32);

U32 f5964(wasmcomponentldInstance*,U32,U32,U32);

U32 f5965(wasmcomponentldInstance*,U32,U32);

U32 f5966(wasmcomponentldInstance*,U32,U32,U32);

U32 f5967(wasmcomponentldInstance*,U32,U32,U32);

U32 f5968(wasmcomponentldInstance*,U32,U32);

U32 f5969(wasmcomponentldInstance*,U32,U32);

U32 f5970(wasmcomponentldInstance*,U32);

U32 f5971(wasmcomponentldInstance*,U32,U32);

U32 f5972(wasmcomponentldInstance*,U32,U32);

U32 f5973(wasmcomponentldInstance*,U32,U32);

U32 f5974(wasmcomponentldInstance*,U32,U32);

U32 f5975(wasmcomponentldInstance*,U32,U32);

U32 f5976(wasmcomponentldInstance*,U32,U32);

U32 f5977(wasmcomponentldInstance*,U32,U32);

U32 f5978(wasmcomponentldInstance*,U32,U32,U32);

U32 f5979(wasmcomponentldInstance*,U32,U32);

U32 f5980(wasmcomponentldInstance*,U32,U32);

U32 f5981(wasmcomponentldInstance*,U32,U32);

U32 f5982(wasmcomponentldInstance*,U32,U32);

U32 f5983(wasmcomponentldInstance*,U32);

U32 f5984(wasmcomponentldInstance*,U32,U32);

U32 f5985(wasmcomponentldInstance*,U32,U32);

U32 f5986(wasmcomponentldInstance*,U32,U32);

U32 f5987(wasmcomponentldInstance*,U32,U32);

U32 f5988(wasmcomponentldInstance*,U32,U32);

U32 f5989(wasmcomponentldInstance*,U32,U32);

U32 f5990(wasmcomponentldInstance*,U32,U32);

U32 f5991(wasmcomponentldInstance*,U32,U32);

U32 f5992(wasmcomponentldInstance*,U32,U32);

U32 f5993(wasmcomponentldInstance*,U32);

U32 f5994(wasmcomponentldInstance*,U32,U32);

U32 f5995(wasmcomponentldInstance*,U32,U32);

U32 f5996(wasmcomponentldInstance*,U32,U32);

U32 f5997(wasmcomponentldInstance*,U32,U32);

U32 f5998(wasmcomponentldInstance*,U32);

U32 f5999(wasmcomponentldInstance*,U32,U32,U32);

U32 f6000(wasmcomponentldInstance*,U32,U32,U32);

U32 f6001(wasmcomponentldInstance*,U32,U32,U32);

U32 f6002(wasmcomponentldInstance*,U32,U32,U32);

U32 f6003(wasmcomponentldInstance*,U32,U32,U32);

U32 f6004(wasmcomponentldInstance*,U32,U32,U32);

U32 f6005(wasmcomponentldInstance*,U32,U32,U32);

U32 f6006(wasmcomponentldInstance*,U32,U32,U32);

U32 f6007(wasmcomponentldInstance*,U32,U32,U32);

U32 f6008(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6009(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6010(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6011(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6012(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6013(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6014(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6015(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6016(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6017(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6018(wasmcomponentldInstance*,U32,U32,U32);

U32 f6019(wasmcomponentldInstance*,U32,U32,U32);

U32 f6020(wasmcomponentldInstance*,U32,U32,U32);

U32 f6021(wasmcomponentldInstance*,U32,U32,U32);

U32 f6022(wasmcomponentldInstance*,U32,U32,U32);

U32 f6023(wasmcomponentldInstance*,U32,U32,U32);

U32 f6024(wasmcomponentldInstance*,U32,U32,U32);

U32 f6025(wasmcomponentldInstance*,U32,U32,U32);

U32 f6026(wasmcomponentldInstance*,U32,U32,U32);

U32 f6027(wasmcomponentldInstance*,U32,U32,U32);

U32 f6028(wasmcomponentldInstance*,U32,U32,U32);

U32 f6029(wasmcomponentldInstance*,U32);

U32 f6030(wasmcomponentldInstance*,U32,U32);

U32 f6031(wasmcomponentldInstance*,U32,U32);

U32 f6032(wasmcomponentldInstance*,U32);

U32 f6033(wasmcomponentldInstance*,U32,U32);

U32 f6034(wasmcomponentldInstance*,U32,U32);

U32 f6035(wasmcomponentldInstance*,U32,U32);

U32 f6036(wasmcomponentldInstance*,U32,U32,U32);

U32 f6037(wasmcomponentldInstance*,U32,U32);

U32 f6038(wasmcomponentldInstance*,U32,U32,U32);

U32 f6039(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6040(wasmcomponentldInstance*,U32,U32,U32);

U32 f6041(wasmcomponentldInstance*,U32,U32,U32);

U32 f6042(wasmcomponentldInstance*,U32);

U32 f6043(wasmcomponentldInstance*,U32);

void f6044(wasmcomponentldInstance*,U32,U32);

U32 f6045(wasmcomponentldInstance*,U32,U32);

U32 f6046(wasmcomponentldInstance*,U32,U32);

void f6047(wasmcomponentldInstance*,U32,U32,U32,U32,U64);

U32 f6048(wasmcomponentldInstance*,U32);

U32 f6049(wasmcomponentldInstance*,U32);

U32 f6050(wasmcomponentldInstance*,U32);

U32 f6051(wasmcomponentldInstance*,U32);

U32 f6052(wasmcomponentldInstance*,U32);

U32 f6053(wasmcomponentldInstance*,U32,U32);

U32 f6054(wasmcomponentldInstance*,U32,U32);

U32 f6055(wasmcomponentldInstance*,U32,U32);

void f6056(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6057(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6058(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f6059(wasmcomponentldInstance*,U32,U32);

U32 f6060(wasmcomponentldInstance*,U32,U32);

U32 f6061(wasmcomponentldInstance*,U32,U32);

U32 f6062(wasmcomponentldInstance*,U32,U32);

void f6063(wasmcomponentldInstance*,U32,U32,U32);

void f6064(wasmcomponentldInstance*,U32,U32,U32);

U32 f6065(wasmcomponentldInstance*,U32,U32);

void f6066(wasmcomponentldInstance*,U32,U32,U32);

void f6067(wasmcomponentldInstance*,U32,U32,U32,U32,U64);

void f6068(wasmcomponentldInstance*,U32,U32,U32);

U32 f6069(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6070(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6071(wasmcomponentldInstance*,U32,U32,U32);

void f6072(wasmcomponentldInstance*,U32,U32,U32);

void f6073(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6074(wasmcomponentldInstance*,U32,U32,U32);

void f6075(wasmcomponentldInstance*,U32,U32,U32);

void f6076(wasmcomponentldInstance*,U32,U32);

void f6077(wasmcomponentldInstance*,U32,U32);

void f6078(wasmcomponentldInstance*,U32,U32,U32);

U32 f6079(wasmcomponentldInstance*,U32,U32);

U32 f6080(wasmcomponentldInstance*,U32,U32);

void f6081(wasmcomponentldInstance*,U32,U32,U32);

void f6082(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6083(wasmcomponentldInstance*,U32,U32,U32);

U32 f6084(wasmcomponentldInstance*,U32,U32,U32);

U32 f6085(wasmcomponentldInstance*,U32,U32,U32);

U32 f6086(wasmcomponentldInstance*,U32,U32,U32);

U32 f6087(wasmcomponentldInstance*,U32,U32,U32);

void f6088(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6089(wasmcomponentldInstance*,U32,U32,U32);

void f6090(wasmcomponentldInstance*,U32,U32,U32);

U32 f6091(wasmcomponentldInstance*,U32,U32,U32);

void f6092(wasmcomponentldInstance*,U32);

void f6093(wasmcomponentldInstance*,U32,U32,U32);

U32 f6094(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6095(wasmcomponentldInstance*,U32,U32,U32);

U32 f6096(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6097(wasmcomponentldInstance*,U32,U32,U32);

void f6098(wasmcomponentldInstance*,U32,U32,U32);

void f6099(wasmcomponentldInstance*,U32,U32,U32);

void f6100(wasmcomponentldInstance*,U32,U32,U32);

void f6101(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6102(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6103(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6104(wasmcomponentldInstance*,U32);

U32 f6105(wasmcomponentldInstance*,U32);

U32 f6106(wasmcomponentldInstance*,U32);

U32 f6107(wasmcomponentldInstance*,U32,U32);

U32 f6108(wasmcomponentldInstance*,U32,U32);

U32 f6109(wasmcomponentldInstance*,U32,U32);

U32 f6110(wasmcomponentldInstance*,U32,U32);

U32 f6111(wasmcomponentldInstance*,U32,U32,U32);

U32 f6112(wasmcomponentldInstance*,U32,U32,U32);

U32 f6113(wasmcomponentldInstance*,U32,U32,U32);

U32 f6114(wasmcomponentldInstance*,U32,U32);

U32 f6115(wasmcomponentldInstance*,U32,U32);

U32 f6116(wasmcomponentldInstance*,U32,U32);

U32 f6117(wasmcomponentldInstance*,U32,U32);

U32 f6118(wasmcomponentldInstance*,U32,U32);

U32 f6119(wasmcomponentldInstance*,U32,U32);

U32 f6120(wasmcomponentldInstance*,U32,U32);

U32 f6121(wasmcomponentldInstance*,U32,U32,U32);

U32 f6122(wasmcomponentldInstance*,U32,U32,U32);

U32 f6123(wasmcomponentldInstance*,U32,U32,U32);

U32 f6124(wasmcomponentldInstance*,U32,U32,U32);

U32 f6125(wasmcomponentldInstance*,U32,U32,U32);

U32 f6126(wasmcomponentldInstance*,U32,U32,U32);

U32 f6127(wasmcomponentldInstance*,U32,U32,U32);

U32 f6128(wasmcomponentldInstance*,U32,U32,U32);

U32 f6129(wasmcomponentldInstance*,U32,U32);

U32 f6130(wasmcomponentldInstance*,U32,U32);

U32 f6131(wasmcomponentldInstance*,U32,U32);

U32 f6132(wasmcomponentldInstance*,U32,U32);

U32 f6133(wasmcomponentldInstance*,U32,U32);

U32 f6134(wasmcomponentldInstance*,U32,U32);

U32 f6135(wasmcomponentldInstance*,U32,U32);

U32 f6136(wasmcomponentldInstance*,U32,U32);

U32 f6137(wasmcomponentldInstance*,U32,U32);

U32 f6138(wasmcomponentldInstance*,U32,U32);

U32 f6139(wasmcomponentldInstance*,U32,U32);

U32 f6140(wasmcomponentldInstance*,U32,U32);

U32 f6141(wasmcomponentldInstance*,U32,U32);

U32 f6142(wasmcomponentldInstance*,U32,U32);

U32 f6143(wasmcomponentldInstance*,U32);

U32 f6144(wasmcomponentldInstance*,U32);

U32 f6145(wasmcomponentldInstance*,U32);

U32 f6146(wasmcomponentldInstance*,U32);

U32 f6147(wasmcomponentldInstance*,U32);

U32 f6148(wasmcomponentldInstance*,U32);

U32 f6149(wasmcomponentldInstance*,U32);

U32 f6150(wasmcomponentldInstance*,U32);

U32 f6151(wasmcomponentldInstance*,U32);

U32 f6152(wasmcomponentldInstance*,U32);

U32 f6153(wasmcomponentldInstance*,U32);

U32 f6154(wasmcomponentldInstance*,U32);

U32 f6155(wasmcomponentldInstance*,U32);

U32 f6156(wasmcomponentldInstance*,U32);

U32 f6157(wasmcomponentldInstance*,U32);

U32 f6158(wasmcomponentldInstance*,U32);

U32 f6159(wasmcomponentldInstance*,U32);

U32 f6160(wasmcomponentldInstance*,U32);

U32 f6161(wasmcomponentldInstance*,U32,U32);

U32 f6162(wasmcomponentldInstance*,U32,U32);

U32 f6163(wasmcomponentldInstance*,U32,U32);

U32 f6164(wasmcomponentldInstance*,U32,U32);

U32 f6165(wasmcomponentldInstance*,U32);

U32 f6166(wasmcomponentldInstance*,U32);

U32 f6167(wasmcomponentldInstance*,U32);

U32 f6168(wasmcomponentldInstance*,U32);

U32 f6169(wasmcomponentldInstance*,U32);

U32 f6170(wasmcomponentldInstance*,U32);

U32 f6171(wasmcomponentldInstance*,U32);

U32 f6172(wasmcomponentldInstance*,U32);

U32 f6173(wasmcomponentldInstance*,U32);

U32 f6174(wasmcomponentldInstance*,U32);

U32 f6175(wasmcomponentldInstance*,U32);

U32 f6176(wasmcomponentldInstance*,U32);

U32 f6177(wasmcomponentldInstance*,U32,U32);

U32 f6178(wasmcomponentldInstance*,U32,U32);

U32 f6179(wasmcomponentldInstance*,U32,U32);

U32 f6180(wasmcomponentldInstance*,U32,U32);

U32 f6181(wasmcomponentldInstance*,U32,U32,U32);

U32 f6182(wasmcomponentldInstance*,U32);

U32 f6183(wasmcomponentldInstance*,U32);

U32 f6184(wasmcomponentldInstance*,U32);

U32 f6185(wasmcomponentldInstance*,U32,U32);

U32 f6186(wasmcomponentldInstance*,U32,U32);

U32 f6187(wasmcomponentldInstance*,U32,U32);

U32 f6188(wasmcomponentldInstance*,U32,U32);

U32 f6189(wasmcomponentldInstance*,U32);

void f6190(wasmcomponentldInstance*,U32);

void f6191(wasmcomponentldInstance*,U32);

void f6192(wasmcomponentldInstance*,U32);

void f6193(wasmcomponentldInstance*,U32);

void f6194(wasmcomponentldInstance*,U32);

void f6195(wasmcomponentldInstance*,U32);

void f6196(wasmcomponentldInstance*,U32);

void f6197(wasmcomponentldInstance*,U32);

void f6198(wasmcomponentldInstance*,U32,U32);

U32 f6199(wasmcomponentldInstance*,U32,U32);

U32 f6200(wasmcomponentldInstance*,U32,U32);

U32 f6201(wasmcomponentldInstance*,U32,U32,U32);

U32 f6202(wasmcomponentldInstance*,U32,U32,U32);

U32 f6203(wasmcomponentldInstance*,U32,U32);

U32 f6204(wasmcomponentldInstance*,U32,U32,U32);

U32 f6205(wasmcomponentldInstance*,U32,U32);

void f6206(wasmcomponentldInstance*,U32,U32);

void f6207(wasmcomponentldInstance*,U32,U32,U32);

void f6208(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6209(wasmcomponentldInstance*,U32,U32);

void f6210(wasmcomponentldInstance*,U32,U32);

U32 f6211(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6212(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6213(wasmcomponentldInstance*,U32,U32);

void f6214(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6215(wasmcomponentldInstance*,U32,U32);

U32 f6216(wasmcomponentldInstance*,U32);

void f6217(wasmcomponentldInstance*,U32,U32,U32);

void f6218(wasmcomponentldInstance*,U32,U32,U32);

void f6219(wasmcomponentldInstance*,U32,U32);

void f6220(wasmcomponentldInstance*,U32,U32);

void f6221(wasmcomponentldInstance*,U32,U32);

void f6222(wasmcomponentldInstance*,U32,U32);

void f6223(wasmcomponentldInstance*,U32,U32);

void f6224(wasmcomponentldInstance*,U32,U32);

void f6225(wasmcomponentldInstance*,U32,U32,U32);

void f6226(wasmcomponentldInstance*,U32,U32);

void f6227(wasmcomponentldInstance*,U32,U32);

void f6228(wasmcomponentldInstance*,U32,U32);

void f6229(wasmcomponentldInstance*,U32,U32);

void f6230(wasmcomponentldInstance*,U32,U32,U32);

void f6231(wasmcomponentldInstance*,U32,U32);

void f6232(wasmcomponentldInstance*,U32,U32);

void f6233(wasmcomponentldInstance*,U32,U32);

void f6234(wasmcomponentldInstance*,U32);

void f6235(wasmcomponentldInstance*,U32);

void f6236(wasmcomponentldInstance*,U32);

void f6237(wasmcomponentldInstance*,U32);

void f6238(wasmcomponentldInstance*,U32);

U32 f6239(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6240(wasmcomponentldInstance*,U32,U32);

U32 f6241(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6242(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f6243(wasmcomponentldInstance*,U32,U32,U32);

void f6244(wasmcomponentldInstance*,U32,U32);

void f6245(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6246(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6247(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6248(wasmcomponentldInstance*,U32,U32);

void f6249(wasmcomponentldInstance*,U32,U32);

void f6250(wasmcomponentldInstance*,U32,U32,U32);

void f6251(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6252(wasmcomponentldInstance*,U32,U32,U32);

void f6253(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6254(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6255(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6256(wasmcomponentldInstance*,U32,U32,U32);

void f6257(wasmcomponentldInstance*,U32,U32,U32);

void f6258(wasmcomponentldInstance*,U32,U32,U32);

void f6259(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6260(wasmcomponentldInstance*,U32,U32,U32);

void f6261(wasmcomponentldInstance*,U32,U32);

void f6262(wasmcomponentldInstance*,U32,U32);

void f6263(wasmcomponentldInstance*,U32,U32);

U32 f6264(wasmcomponentldInstance*,U32,U32,U32);

U32 f6265(wasmcomponentldInstance*,U32,U32);

U32 f6266(wasmcomponentldInstance*,U32,U32,U32);

U32 f6267(wasmcomponentldInstance*,U32,U32);

U32 f6268(wasmcomponentldInstance*,U32,U32);

U32 f6269(wasmcomponentldInstance*,U32,U32);

U32 f6270(wasmcomponentldInstance*,U32,U32);

U32 f6271(wasmcomponentldInstance*,U32);

U32 f6272(wasmcomponentldInstance*,U32,U32,U32);

U32 f6273(wasmcomponentldInstance*,U32);

U32 f6274(wasmcomponentldInstance*,U32,U32);

U32 f6275(wasmcomponentldInstance*,U32);

U32 f6276(wasmcomponentldInstance*,U32);

U32 f6277(wasmcomponentldInstance*,U32);

U32 f6278(wasmcomponentldInstance*,U32);

U32 f6279(wasmcomponentldInstance*,U32,U32);

U32 f6280(wasmcomponentldInstance*,U32,U32,U32);

U32 f6281(wasmcomponentldInstance*,U32);

U32 f6282(wasmcomponentldInstance*,U32);

U32 f6283(wasmcomponentldInstance*,U32,U32);

void f6284(wasmcomponentldInstance*,U32,U32);

void f6285(wasmcomponentldInstance*,U32,U32);

U32 f6286(wasmcomponentldInstance*,U32);

void f6287(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6288(wasmcomponentldInstance*,U32,U32,U32);

void f6289(wasmcomponentldInstance*,U32,U32,U32);

U32 f6290(wasmcomponentldInstance*,U32,U32);

U32 f6291(wasmcomponentldInstance*,U32,U32);

U32 f6292(wasmcomponentldInstance*,U32,U32);

void f6293(wasmcomponentldInstance*,U32);

void f6294(wasmcomponentldInstance*,U32);

void f6295(wasmcomponentldInstance*,U32);

void f6296(wasmcomponentldInstance*,U32);

void f6297(wasmcomponentldInstance*,U32,U32);

U32 f6298(wasmcomponentldInstance*,U32,U32);

void f6299(wasmcomponentldInstance*,U32,U32,U32);

void f6300(wasmcomponentldInstance*,U32,U32,U32);

void f6301(wasmcomponentldInstance*,U32,U32,U32);

void f6302(wasmcomponentldInstance*,U32,U32,U32);

void f6303(wasmcomponentldInstance*,U32,U32,U32);

void f6304(wasmcomponentldInstance*,U32);

void f6305(wasmcomponentldInstance*,U32);

void f6306(wasmcomponentldInstance*,U32);

void f6307(wasmcomponentldInstance*,U32);

void f6308(wasmcomponentldInstance*,U32,U32,U32);

void f6309(wasmcomponentldInstance*,U32,U32,U32);

void f6310(wasmcomponentldInstance*,U32,U32,U32);

void f6311(wasmcomponentldInstance*,U32,U32,U32);

void f6312(wasmcomponentldInstance*,U32,U32,U32);

void f6313(wasmcomponentldInstance*,U32,U32,U32);

void f6314(wasmcomponentldInstance*,U32,U32,U32);

void f6315(wasmcomponentldInstance*,U32,U32,U32);

void f6316(wasmcomponentldInstance*,U32,U32,U32);

void f6317(wasmcomponentldInstance*,U32,U32,U32);

void f6318(wasmcomponentldInstance*,U32,U32,U32);

void f6319(wasmcomponentldInstance*,U32,U32,U32);

void f6320(wasmcomponentldInstance*,U32,U32,U32);

void f6321(wasmcomponentldInstance*,U32,U32,U32);

void f6322(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6323(wasmcomponentldInstance*,U32,U32,U32);

void f6324(wasmcomponentldInstance*,U32,U32,U32);

void f6325(wasmcomponentldInstance*,U32,U32,U32);

void f6326(wasmcomponentldInstance*,U32,U32,U32);

void f6327(wasmcomponentldInstance*,U32,U32,U32);

void f6328(wasmcomponentldInstance*,U32,U32,U32);

void f6329(wasmcomponentldInstance*,U32,U32,U32);

void f6330(wasmcomponentldInstance*,U32,U32,U32);

U32 f6331(wasmcomponentldInstance*,U32,U32);

U32 f6332(wasmcomponentldInstance*,U32,U32);

U32 f6333(wasmcomponentldInstance*,U32,U32);

void f6334(wasmcomponentldInstance*,U32);

void f6335(wasmcomponentldInstance*,U32);

void f6336(wasmcomponentldInstance*,U32);

U32 f6337(wasmcomponentldInstance*,U32,U32);

U32 f6338(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6339(wasmcomponentldInstance*,U32,U32,U32);

U32 f6340(wasmcomponentldInstance*,U32,U32);

U32 f6341(wasmcomponentldInstance*,U32,U32);

U32 f6342(wasmcomponentldInstance*,U32,U32);

void f6343(wasmcomponentldInstance*,U32,U32,U32);

void f6344(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f6345(wasmcomponentldInstance*,U32,U32,U64);

U32 f6346(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6347(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6348(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6349(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6350(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6351(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f6352(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6353(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6354(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6355(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6356(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6357(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6358(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6359(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U64);

void f6360(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6361(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6362(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6363(wasmcomponentldInstance*,U32,U32);

U32 f6364(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6365(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f6366(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6367(wasmcomponentldInstance*,U64,U32,U32,U32);

U32 f6368(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6369(wasmcomponentldInstance*,U32,U32);

U32 f6370(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6371(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f6372(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f6373(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6374(wasmcomponentldInstance*,U32);

void f6375(wasmcomponentldInstance*,U32,U32);

void f6376(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6377(wasmcomponentldInstance*,U32);

U32 f6378(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6379(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6380(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6381(wasmcomponentldInstance*,U32,U32);

U32 f6382(wasmcomponentldInstance*,U32,U32);

U32 f6383(wasmcomponentldInstance*,U32,U32);

void f6384(wasmcomponentldInstance*,U32);

U32 f6385(wasmcomponentldInstance*,U32,U32);

U32 f6386(wasmcomponentldInstance*,U32,U32);

U32 f6387(wasmcomponentldInstance*,U32);

U32 f6388(wasmcomponentldInstance*,U32,U32);

U32 f6389(wasmcomponentldInstance*,U32,U32);

U32 f6390(wasmcomponentldInstance*,U32,U32);

U32 f6391(wasmcomponentldInstance*,U32,U32,U32);

U32 f6392(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6393(wasmcomponentldInstance*,U32,U32);

U32 f6394(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6395(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6396(wasmcomponentldInstance*,U32,U32);

void f6397(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f6398(wasmcomponentldInstance*,U32,U32);

void f6399(wasmcomponentldInstance*,U32,U32,U32);

U32 f6400(wasmcomponentldInstance*,U32,U32);

U32 f6401(wasmcomponentldInstance*,U32,U32,U32);

U32 f6402(wasmcomponentldInstance*,U32,U32,U32);

U32 f6403(wasmcomponentldInstance*,U32,U32,U32);

U32 f6404(wasmcomponentldInstance*,U32,U32,U32);

U32 f6405(wasmcomponentldInstance*,U32,U32,U32);

void f6406(wasmcomponentldInstance*,U32,U32,U32);

U32 f6407(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6408(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6409(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6410(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6411(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6412(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6413(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6414(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6415(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6416(wasmcomponentldInstance*,U32,U32);

void f6417(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6418(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6419(wasmcomponentldInstance*,U32,U32,U32);

U32 f6420(wasmcomponentldInstance*,U32,U32,U32);

U32 f6421(wasmcomponentldInstance*,U32,U32,U32);

U32 f6422(wasmcomponentldInstance*,U32,U32);

U32 f6423(wasmcomponentldInstance*,U32,U32);

U32 f6424(wasmcomponentldInstance*,U32,U32);

void f6425(wasmcomponentldInstance*,U32);

U32 f6426(wasmcomponentldInstance*,U32,U32);

void f6427(wasmcomponentldInstance*,U32,U32,U32);

U32 f6428(wasmcomponentldInstance*,U32,U32);

void f6429(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6430(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6431(wasmcomponentldInstance*,U32,U32);

void f6432(wasmcomponentldInstance*,U32,U32,U32);

void f6433(wasmcomponentldInstance*,U32,U32,U32);

void f6434(wasmcomponentldInstance*,U32,U32,U32);

U32 f6435(wasmcomponentldInstance*,U32,U32);

void f6436(wasmcomponentldInstance*,U32,U32,U32);

void f6437(wasmcomponentldInstance*,U32,U32,U32);

U32 f6438(wasmcomponentldInstance*,U32,U32);

U32 f6439(wasmcomponentldInstance*,U32,U32);

U32 f6440(wasmcomponentldInstance*,U32,U32);

U32 f6441(wasmcomponentldInstance*,U32,U32,U32);

void f6442(wasmcomponentldInstance*,U32,U32,U32);

U32 f6443(wasmcomponentldInstance*,U32,U32);

U32 f6444(wasmcomponentldInstance*,U32,U32,U32);

U32 f6445(wasmcomponentldInstance*,U32,U32,U32);

U32 f6446(wasmcomponentldInstance*,U32,U32,U32);

U32 f6447(wasmcomponentldInstance*,U32,U32,U32);

U32 f6448(wasmcomponentldInstance*,U32,U32,U32);

U32 f6449(wasmcomponentldInstance*,U32,U32);

U32 f6450(wasmcomponentldInstance*,U32,U32);

U32 f6451(wasmcomponentldInstance*,U32,U32);

U32 f6452(wasmcomponentldInstance*,U32,U32);

void f6453(wasmcomponentldInstance*,U32,U32,U32);

U32 f6454(wasmcomponentldInstance*,U32,U32);

U32 f6455(wasmcomponentldInstance*,U32,U32);

U32 f6456(wasmcomponentldInstance*,U32,U32);

void f6457(wasmcomponentldInstance*,U32,U32);

void f6458(wasmcomponentldInstance*,U32,U32);

void f6459(wasmcomponentldInstance*,U32,U32);

void f6460(wasmcomponentldInstance*,U32,U32);

void f6461(wasmcomponentldInstance*,U32,U32);

void f6462(wasmcomponentldInstance*,U32,U32);

void f6463(wasmcomponentldInstance*,U32,U32);

void f6464(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6465(wasmcomponentldInstance*,U32,U32);

U32 f6466(wasmcomponentldInstance*,U32,U32,U32);

U32 f6467(wasmcomponentldInstance*,U32,U32,U32);

void f6468(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6469(wasmcomponentldInstance*,U32,U32,U32);

U32 f6470(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6471(wasmcomponentldInstance*,U32,U32);

void f6472(wasmcomponentldInstance*,U32,U32,U32);

void f6473(wasmcomponentldInstance*,U32,U32);

U32 f6474(wasmcomponentldInstance*,U32,U32,U32);

U32 f6475(wasmcomponentldInstance*,U32,U32,U32);

U32 f6476(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6477(wasmcomponentldInstance*,U32,U32,U32);

void f6478(wasmcomponentldInstance*,U32);

U32 f6479(wasmcomponentldInstance*,U32,U32);

void f6480(wasmcomponentldInstance*,U32);

void f6481(wasmcomponentldInstance*,U32,U32);

U32 f6482(wasmcomponentldInstance*,U32,U32);

U32 f6483(wasmcomponentldInstance*,U32,U32,U32);

U32 f6484(wasmcomponentldInstance*,U32,U32);

U32 f6485(wasmcomponentldInstance*,U32,U32);

U32 f6486(wasmcomponentldInstance*,U32,U32);

U32 f6487(wasmcomponentldInstance*,U32,U32,U32);

U32 f6488(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6489(wasmcomponentldInstance*,U32,U32,U32);

U32 f6490(wasmcomponentldInstance*,U32,U32,U32);

U32 f6491(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6492(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6493(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f6494(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f6495(wasmcomponentldInstance*,U32,U64);

U32 f6496(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6497(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6498(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6499(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6500(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6501(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6502(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6503(wasmcomponentldInstance*,U32,U32,U32);

void f6504(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f6505(wasmcomponentldInstance*,U32,U64);

U32 f6506(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6507(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6508(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6509(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f6510(wasmcomponentldInstance*,U64,U32,U32);

U32 f6511(wasmcomponentldInstance*,U32,U32,U32,U32);

void f6512(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6513(wasmcomponentldInstance*,U32);

void f6514(wasmcomponentldInstance*,U32,U32);

void f6515(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6516(wasmcomponentldInstance*,U32);

U32 f6517(wasmcomponentldInstance*,U32,U32);

U32 f6518(wasmcomponentldInstance*,U32,U32,U32);

U32 f6519(wasmcomponentldInstance*,U32,U32);

U32 f6520(wasmcomponentldInstance*,U32,U32);

U32 f6521(wasmcomponentldInstance*,U32,U32);

U32 f6522(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f6523(wasmcomponentldInstance*,U32,U32);

U32 f6524(wasmcomponentldInstance*,U32,U32);

U32 f6525(wasmcomponentldInstance*,U32,U32);

U32 f6526(wasmcomponentldInstance*,U32,U32);

U32 f6527(wasmcomponentldInstance*,U32,U32);

U32 f6528(wasmcomponentldInstance*,U32,U32);

U32 f6529(wasmcomponentldInstance*,U32,U32);

U32 f6530(wasmcomponentldInstance*,U32,U32);

U32 f6531(wasmcomponentldInstance*,U32,U32);

U32 f6532(wasmcomponentldInstance*,U32,U32);

U32 f6533(wasmcomponentldInstance*,U32,U32);

U32 f6534(wasmcomponentldInstance*,U32,U32);

U32 f6535(wasmcomponentldInstance*,U32,U32);

U32 f6536(wasmcomponentldInstance*,U32,U32);

U32 f6537(wasmcomponentldInstance*,U32,U32,U32);

U32 f6538(wasmcomponentldInstance*,U32,U32,U32);

U32 f6539(wasmcomponentldInstance*,U32,U32,U32);

U32 f6540(wasmcomponentldInstance*,U32,U32,U32);

U32 f6541(wasmcomponentldInstance*,U32,U32,U32);

U32 f6542(wasmcomponentldInstance*,U32,U32,U32);

U32 f6543(wasmcomponentldInstance*,U32,U32,U32);

U32 f6544(wasmcomponentldInstance*,U32,U32,U32);

U32 f6545(wasmcomponentldInstance*,U32,U32);

U32 f6546(wasmcomponentldInstance*,U32,U32);

U32 f6547(wasmcomponentldInstance*,U32,U32);

U32 f6548(wasmcomponentldInstance*,U32,U32);

U32 f6549(wasmcomponentldInstance*,U32,U32);

U32 f6550(wasmcomponentldInstance*,U32,U32);

U32 f6551(wasmcomponentldInstance*,U32,U32);

U32 f6552(wasmcomponentldInstance*,U32,U32);

U32 f6553(wasmcomponentldInstance*,U32,U32);

U32 f6554(wasmcomponentldInstance*,U32,U32);

U32 f6555(wasmcomponentldInstance*,U32,U32);

U32 f6556(wasmcomponentldInstance*,U32,U32);

U32 f6557(wasmcomponentldInstance*,U32,U32);

U32 f6558(wasmcomponentldInstance*,U32,U32);

U32 f6559(wasmcomponentldInstance*,U32,U32);

U32 f6560(wasmcomponentldInstance*,U32,U32);

U32 f6561(wasmcomponentldInstance*,U32);

U32 f6562(wasmcomponentldInstance*,U32);

U32 f6563(wasmcomponentldInstance*,U32);

U32 f6564(wasmcomponentldInstance*,U32);

U32 f6565(wasmcomponentldInstance*,U32);

U32 f6566(wasmcomponentldInstance*,U32);

U32 f6567(wasmcomponentldInstance*,U32);

U32 f6568(wasmcomponentldInstance*,U32);

U32 f6569(wasmcomponentldInstance*,U32);

U32 f6570(wasmcomponentldInstance*,U32);

U32 f6571(wasmcomponentldInstance*,U32);

U32 f6572(wasmcomponentldInstance*,U32);

U32 f6573(wasmcomponentldInstance*,U32);

U32 f6574(wasmcomponentldInstance*,U32);

U32 f6575(wasmcomponentldInstance*,U32);

U32 f6576(wasmcomponentldInstance*,U32);

U32 f6577(wasmcomponentldInstance*,U32);

U32 f6578(wasmcomponentldInstance*,U32);

U32 f6579(wasmcomponentldInstance*,U32);

U32 f6580(wasmcomponentldInstance*,U32);

U32 f6581(wasmcomponentldInstance*,U32);

U32 f6582(wasmcomponentldInstance*,U32);

U32 f6583(wasmcomponentldInstance*,U32);

U32 f6584(wasmcomponentldInstance*,U32);

U32 f6585(wasmcomponentldInstance*,U32);

U32 f6586(wasmcomponentldInstance*,U32);

U32 f6587(wasmcomponentldInstance*,U32);

U32 f6588(wasmcomponentldInstance*,U32);

U32 f6589(wasmcomponentldInstance*,U32);

U32 f6590(wasmcomponentldInstance*,U32);

U32 f6591(wasmcomponentldInstance*,U32);

U32 f6592(wasmcomponentldInstance*,U32);

U32 f6593(wasmcomponentldInstance*,U32);

U32 f6594(wasmcomponentldInstance*,U32);

U32 f6595(wasmcomponentldInstance*,U32);

U32 f6596(wasmcomponentldInstance*,U32);

U32 f6597(wasmcomponentldInstance*,U32);

U32 f6598(wasmcomponentldInstance*,U32);

U32 f6599(wasmcomponentldInstance*,U32);

U32 f6600(wasmcomponentldInstance*,U32);

U32 f6601(wasmcomponentldInstance*,U32);

U32 f6602(wasmcomponentldInstance*,U32);

U32 f6603(wasmcomponentldInstance*,U32);

U32 f6604(wasmcomponentldInstance*,U32);

U32 f6605(wasmcomponentldInstance*,U32);

U32 f6606(wasmcomponentldInstance*,U32);

U32 f6607(wasmcomponentldInstance*,U32);

U32 f6608(wasmcomponentldInstance*,U32);

U32 f6609(wasmcomponentldInstance*,U32);

U32 f6610(wasmcomponentldInstance*,U32);

U32 f6611(wasmcomponentldInstance*,U32);

U32 f6612(wasmcomponentldInstance*,U32);

U32 f6613(wasmcomponentldInstance*,U32);

U32 f6614(wasmcomponentldInstance*,U32);

U32 f6615(wasmcomponentldInstance*,U32);

U32 f6616(wasmcomponentldInstance*,U32);

U32 f6617(wasmcomponentldInstance*,U32);

U32 f6618(wasmcomponentldInstance*,U32);

U32 f6619(wasmcomponentldInstance*,U32);

U32 f6620(wasmcomponentldInstance*,U32);

U32 f6621(wasmcomponentldInstance*,U32);

U32 f6622(wasmcomponentldInstance*,U32);

U32 f6623(wasmcomponentldInstance*,U32);

U32 f6624(wasmcomponentldInstance*,U32);

U32 f6625(wasmcomponentldInstance*,U32);

U32 f6626(wasmcomponentldInstance*,U32);

U32 f6627(wasmcomponentldInstance*,U32);

U32 f6628(wasmcomponentldInstance*,U32);

U32 f6629(wasmcomponentldInstance*,U32);

U32 f6630(wasmcomponentldInstance*,U32);

U32 f6631(wasmcomponentldInstance*,U32);

U32 f6632(wasmcomponentldInstance*,U32);

U32 f6633(wasmcomponentldInstance*,U32);

U32 f6634(wasmcomponentldInstance*,U32);

U32 f6635(wasmcomponentldInstance*,U32);

U32 f6636(wasmcomponentldInstance*,U32);

U32 f6637(wasmcomponentldInstance*,U32);

U32 f6638(wasmcomponentldInstance*,U32);

U32 f6639(wasmcomponentldInstance*,U32);

U32 f6640(wasmcomponentldInstance*,U32);

U32 f6641(wasmcomponentldInstance*,U32);

U32 f6642(wasmcomponentldInstance*,U32);

U32 f6643(wasmcomponentldInstance*,U32);

U32 f6644(wasmcomponentldInstance*,U32);

U32 f6645(wasmcomponentldInstance*,U32);

U32 f6646(wasmcomponentldInstance*,U32);

U32 f6647(wasmcomponentldInstance*,U32);

U32 f6648(wasmcomponentldInstance*,U32);

U32 f6649(wasmcomponentldInstance*,U32);

U32 f6650(wasmcomponentldInstance*,U32);

U32 f6651(wasmcomponentldInstance*,U32);

U32 f6652(wasmcomponentldInstance*,U32);

U32 f6653(wasmcomponentldInstance*,U32);

U32 f6654(wasmcomponentldInstance*,U32);

U32 f6655(wasmcomponentldInstance*,U32);

U32 f6656(wasmcomponentldInstance*,U32);

U32 f6657(wasmcomponentldInstance*,U32);

U32 f6658(wasmcomponentldInstance*,U32);

U32 f6659(wasmcomponentldInstance*,U32);

U32 f6660(wasmcomponentldInstance*,U32);

U32 f6661(wasmcomponentldInstance*,U32);

U32 f6662(wasmcomponentldInstance*,U32);

U32 f6663(wasmcomponentldInstance*,U32);

U32 f6664(wasmcomponentldInstance*,U32);

U32 f6665(wasmcomponentldInstance*,U32);

U32 f6666(wasmcomponentldInstance*,U32);

U32 f6667(wasmcomponentldInstance*,U32);

U32 f6668(wasmcomponentldInstance*,U32);

U32 f6669(wasmcomponentldInstance*,U32);

U32 f6670(wasmcomponentldInstance*,U32);

U32 f6671(wasmcomponentldInstance*,U32);

U32 f6672(wasmcomponentldInstance*,U32);

U32 f6673(wasmcomponentldInstance*,U32);

U32 f6674(wasmcomponentldInstance*,U32);

U32 f6675(wasmcomponentldInstance*,U32);

U32 f6676(wasmcomponentldInstance*,U32);

U32 f6677(wasmcomponentldInstance*,U32);

U32 f6678(wasmcomponentldInstance*,U32);

U32 f6679(wasmcomponentldInstance*,U32);

U32 f6680(wasmcomponentldInstance*,U32);

U32 f6681(wasmcomponentldInstance*,U32);

U32 f6682(wasmcomponentldInstance*,U32);

U32 f6683(wasmcomponentldInstance*,U32);

U32 f6684(wasmcomponentldInstance*,U32);

U32 f6685(wasmcomponentldInstance*,U32);

U32 f6686(wasmcomponentldInstance*,U32);

U32 f6687(wasmcomponentldInstance*,U32);

U32 f6688(wasmcomponentldInstance*,U32);

U32 f6689(wasmcomponentldInstance*,U32);

U32 f6690(wasmcomponentldInstance*,U32);

U32 f6691(wasmcomponentldInstance*,U32);

U32 f6692(wasmcomponentldInstance*,U32);

U32 f6693(wasmcomponentldInstance*,U32);

U32 f6694(wasmcomponentldInstance*,U32);

U32 f6695(wasmcomponentldInstance*,U32);

U32 f6696(wasmcomponentldInstance*,U32);

U32 f6697(wasmcomponentldInstance*,U32);

U32 f6698(wasmcomponentldInstance*,U32);

U32 f6699(wasmcomponentldInstance*,U32);

U32 f6700(wasmcomponentldInstance*,U32);

U32 f6701(wasmcomponentldInstance*,U32);

U32 f6702(wasmcomponentldInstance*,U32);

U32 f6703(wasmcomponentldInstance*,U32);

U32 f6704(wasmcomponentldInstance*,U32);

U32 f6705(wasmcomponentldInstance*,U32);

U32 f6706(wasmcomponentldInstance*,U32);

U32 f6707(wasmcomponentldInstance*,U32);

U32 f6708(wasmcomponentldInstance*,U32);

U32 f6709(wasmcomponentldInstance*,U32);

U32 f6710(wasmcomponentldInstance*,U32);

U32 f6711(wasmcomponentldInstance*,U32);

U32 f6712(wasmcomponentldInstance*,U32);

U32 f6713(wasmcomponentldInstance*,U32);

U32 f6714(wasmcomponentldInstance*,U32);

U32 f6715(wasmcomponentldInstance*,U32);

U32 f6716(wasmcomponentldInstance*,U32);

U32 f6717(wasmcomponentldInstance*,U32);

U32 f6718(wasmcomponentldInstance*,U32);

U32 f6719(wasmcomponentldInstance*,U32);

U32 f6720(wasmcomponentldInstance*,U32);

U32 f6721(wasmcomponentldInstance*,U32);

U32 f6722(wasmcomponentldInstance*,U32);

U32 f6723(wasmcomponentldInstance*,U32);

U32 f6724(wasmcomponentldInstance*,U32);

U32 f6725(wasmcomponentldInstance*,U32);

U32 f6726(wasmcomponentldInstance*,U32);

U32 f6727(wasmcomponentldInstance*,U32);

U32 f6728(wasmcomponentldInstance*,U32);

U32 f6729(wasmcomponentldInstance*,U32);

U32 f6730(wasmcomponentldInstance*,U32);

U32 f6731(wasmcomponentldInstance*,U32);

U32 f6732(wasmcomponentldInstance*,U32);

U32 f6733(wasmcomponentldInstance*,U32);

U32 f6734(wasmcomponentldInstance*,U32);

U32 f6735(wasmcomponentldInstance*,U32);

U32 f6736(wasmcomponentldInstance*,U32);

U32 f6737(wasmcomponentldInstance*,U32);

U32 f6738(wasmcomponentldInstance*,U32);

U32 f6739(wasmcomponentldInstance*,U32);

U32 f6740(wasmcomponentldInstance*,U32);

U32 f6741(wasmcomponentldInstance*,U32);

U32 f6742(wasmcomponentldInstance*,U32);

U32 f6743(wasmcomponentldInstance*,U32);

U32 f6744(wasmcomponentldInstance*,U32);

U32 f6745(wasmcomponentldInstance*,U32);

U32 f6746(wasmcomponentldInstance*,U32);

U32 f6747(wasmcomponentldInstance*,U32);

U32 f6748(wasmcomponentldInstance*,U32);

U32 f6749(wasmcomponentldInstance*,U32);

U32 f6750(wasmcomponentldInstance*,U32);

U32 f6751(wasmcomponentldInstance*,U32);

U32 f6752(wasmcomponentldInstance*,U32);

U32 f6753(wasmcomponentldInstance*,U32);

U32 f6754(wasmcomponentldInstance*,U32);

U32 f6755(wasmcomponentldInstance*,U32);

U32 f6756(wasmcomponentldInstance*,U32);

U32 f6757(wasmcomponentldInstance*,U32);

U32 f6758(wasmcomponentldInstance*,U32);

U32 f6759(wasmcomponentldInstance*,U32);

U32 f6760(wasmcomponentldInstance*,U32);

U32 f6761(wasmcomponentldInstance*,U32);

U32 f6762(wasmcomponentldInstance*,U32);

U32 f6763(wasmcomponentldInstance*,U32);

U32 f6764(wasmcomponentldInstance*,U32);

U32 f6765(wasmcomponentldInstance*,U32);

U32 f6766(wasmcomponentldInstance*,U32);

U32 f6767(wasmcomponentldInstance*,U32);

U32 f6768(wasmcomponentldInstance*,U32);

U32 f6769(wasmcomponentldInstance*,U32);

U32 f6770(wasmcomponentldInstance*,U32);

U32 f6771(wasmcomponentldInstance*,U32);

U32 f6772(wasmcomponentldInstance*,U32);

U32 f6773(wasmcomponentldInstance*,U32);

U32 f6774(wasmcomponentldInstance*,U32);

U32 f6775(wasmcomponentldInstance*,U32);

U32 f6776(wasmcomponentldInstance*,U32);

U32 f6777(wasmcomponentldInstance*,U32);

U32 f6778(wasmcomponentldInstance*,U32);

U32 f6779(wasmcomponentldInstance*,U32);

U32 f6780(wasmcomponentldInstance*,U32);

U32 f6781(wasmcomponentldInstance*,U32,U32);

U32 f6782(wasmcomponentldInstance*,U32,U32);

U32 f6783(wasmcomponentldInstance*,U32,U32);

U32 f6784(wasmcomponentldInstance*,U32);

U32 f6785(wasmcomponentldInstance*,U32);

U32 f6786(wasmcomponentldInstance*,U32,U32);

U32 f6787(wasmcomponentldInstance*,U32,U32);

U32 f6788(wasmcomponentldInstance*,U32,U32);

U32 f6789(wasmcomponentldInstance*,U32);

U32 f6790(wasmcomponentldInstance*,U32,U32);

U32 f6791(wasmcomponentldInstance*,U32,U32,U32);

U32 f6792(wasmcomponentldInstance*,U32);

U32 f6793(wasmcomponentldInstance*,U32);

U32 f6794(wasmcomponentldInstance*,U32,U32);

U32 f6795(wasmcomponentldInstance*,U32,U32);

U32 f6796(wasmcomponentldInstance*,U32,U32);

U32 f6797(wasmcomponentldInstance*,U32,U32);

U32 f6798(wasmcomponentldInstance*,U32,U32);

U32 f6799(wasmcomponentldInstance*,U32,U32);

U32 f6800(wasmcomponentldInstance*,U32,U32);

U32 f6801(wasmcomponentldInstance*,U32,U32);

U32 f6802(wasmcomponentldInstance*,U32,U32);

U32 f6803(wasmcomponentldInstance*,U32,U32);

U32 f6804(wasmcomponentldInstance*,U32,U32);

U32 f6805(wasmcomponentldInstance*,U32,U32);

U32 f6806(wasmcomponentldInstance*,U32,U32);

U32 f6807(wasmcomponentldInstance*,U32,U32);

U32 f6808(wasmcomponentldInstance*,U32,U32);

U32 f6809(wasmcomponentldInstance*,U32,U32);

U32 f6810(wasmcomponentldInstance*,U32,U32);

U32 f6811(wasmcomponentldInstance*,U32,U32);

U32 f6812(wasmcomponentldInstance*,U32,U32);

U32 f6813(wasmcomponentldInstance*,U32,U32);

U32 f6814(wasmcomponentldInstance*,U32,U32);

U32 f6815(wasmcomponentldInstance*,U32,U32);

U32 f6816(wasmcomponentldInstance*,U32,U32);

U32 f6817(wasmcomponentldInstance*,U32,U32);

U32 f6818(wasmcomponentldInstance*,U32,U32);

U32 f6819(wasmcomponentldInstance*,U32,U32);

U32 f6820(wasmcomponentldInstance*,U32,U32);

U32 f6821(wasmcomponentldInstance*,U32,U32);

U32 f6822(wasmcomponentldInstance*,U32,U32);

U32 f6823(wasmcomponentldInstance*,U32,U32);

U32 f6824(wasmcomponentldInstance*,U32,U64);

U32 f6825(wasmcomponentldInstance*,U32,U32);

U32 f6826(wasmcomponentldInstance*,U32,U64);

U32 f6827(wasmcomponentldInstance*,U32);

U32 f6828(wasmcomponentldInstance*,U32);

U32 f6829(wasmcomponentldInstance*,U32);

U32 f6830(wasmcomponentldInstance*,U32);

U32 f6831(wasmcomponentldInstance*,U32);

U32 f6832(wasmcomponentldInstance*,U32);

U32 f6833(wasmcomponentldInstance*,U32);

U32 f6834(wasmcomponentldInstance*,U32);

U32 f6835(wasmcomponentldInstance*,U32);

U32 f6836(wasmcomponentldInstance*,U32);

U32 f6837(wasmcomponentldInstance*,U32);

U32 f6838(wasmcomponentldInstance*,U32);

U32 f6839(wasmcomponentldInstance*,U32);

U32 f6840(wasmcomponentldInstance*,U32);

U32 f6841(wasmcomponentldInstance*,U32);

U32 f6842(wasmcomponentldInstance*,U32);

U32 f6843(wasmcomponentldInstance*,U32);

U32 f6844(wasmcomponentldInstance*,U32);

U32 f6845(wasmcomponentldInstance*,U32);

U32 f6846(wasmcomponentldInstance*,U32);

U32 f6847(wasmcomponentldInstance*,U32);

U32 f6848(wasmcomponentldInstance*,U32);

U32 f6849(wasmcomponentldInstance*,U32);

U32 f6850(wasmcomponentldInstance*,U32);

U32 f6851(wasmcomponentldInstance*,U32);

U32 f6852(wasmcomponentldInstance*,U32);

U32 f6853(wasmcomponentldInstance*,U32);

U32 f6854(wasmcomponentldInstance*,U32);

U32 f6855(wasmcomponentldInstance*,U32);

U32 f6856(wasmcomponentldInstance*,U32);

U32 f6857(wasmcomponentldInstance*,U32);

U32 f6858(wasmcomponentldInstance*,U32);

U32 f6859(wasmcomponentldInstance*,U32);

U32 f6860(wasmcomponentldInstance*,U32);

U32 f6861(wasmcomponentldInstance*,U32);

U32 f6862(wasmcomponentldInstance*,U32);

U32 f6863(wasmcomponentldInstance*,U32);

U32 f6864(wasmcomponentldInstance*,U32);

U32 f6865(wasmcomponentldInstance*,U32);

U32 f6866(wasmcomponentldInstance*,U32);

U32 f6867(wasmcomponentldInstance*,U32);

U32 f6868(wasmcomponentldInstance*,U32);

U32 f6869(wasmcomponentldInstance*,U32);

U32 f6870(wasmcomponentldInstance*,U32);

U32 f6871(wasmcomponentldInstance*,U32);

U32 f6872(wasmcomponentldInstance*,U32);

U32 f6873(wasmcomponentldInstance*,U32);

U32 f6874(wasmcomponentldInstance*,U32);

U32 f6875(wasmcomponentldInstance*,U32);

U32 f6876(wasmcomponentldInstance*,U32);

U32 f6877(wasmcomponentldInstance*,U32);

U32 f6878(wasmcomponentldInstance*,U32);

U32 f6879(wasmcomponentldInstance*,U32);

U32 f6880(wasmcomponentldInstance*,U32);

U32 f6881(wasmcomponentldInstance*,U32);

U32 f6882(wasmcomponentldInstance*,U32);

U32 f6883(wasmcomponentldInstance*,U32);

U32 f6884(wasmcomponentldInstance*,U32);

U32 f6885(wasmcomponentldInstance*,U32);

U32 f6886(wasmcomponentldInstance*,U32);

U32 f6887(wasmcomponentldInstance*,U32);

U32 f6888(wasmcomponentldInstance*,U32);

U32 f6889(wasmcomponentldInstance*,U32);

U32 f6890(wasmcomponentldInstance*,U32);

U32 f6891(wasmcomponentldInstance*,U32);

U32 f6892(wasmcomponentldInstance*,U32);

U32 f6893(wasmcomponentldInstance*,U32);

U32 f6894(wasmcomponentldInstance*,U32);

U32 f6895(wasmcomponentldInstance*,U32);

U32 f6896(wasmcomponentldInstance*,U32);

U32 f6897(wasmcomponentldInstance*,U32);

U32 f6898(wasmcomponentldInstance*,U32);

U32 f6899(wasmcomponentldInstance*,U32);

U32 f6900(wasmcomponentldInstance*,U32);

U32 f6901(wasmcomponentldInstance*,U32);

U32 f6902(wasmcomponentldInstance*,U32);

U32 f6903(wasmcomponentldInstance*,U32);

U32 f6904(wasmcomponentldInstance*,U32);

U32 f6905(wasmcomponentldInstance*,U32);

U32 f6906(wasmcomponentldInstance*,U32);

U32 f6907(wasmcomponentldInstance*,U32);

U32 f6908(wasmcomponentldInstance*,U32);

U32 f6909(wasmcomponentldInstance*,U32);

U32 f6910(wasmcomponentldInstance*,U32);

U32 f6911(wasmcomponentldInstance*,U32);

U32 f6912(wasmcomponentldInstance*,U32);

U32 f6913(wasmcomponentldInstance*,U32);

U32 f6914(wasmcomponentldInstance*,U32);

U32 f6915(wasmcomponentldInstance*,U32);

U32 f6916(wasmcomponentldInstance*,U32);

U32 f6917(wasmcomponentldInstance*,U32);

U32 f6918(wasmcomponentldInstance*,U32);

U32 f6919(wasmcomponentldInstance*,U32);

U32 f6920(wasmcomponentldInstance*,U32);

U32 f6921(wasmcomponentldInstance*,U32);

U32 f6922(wasmcomponentldInstance*,U32);

U32 f6923(wasmcomponentldInstance*,U32);

U32 f6924(wasmcomponentldInstance*,U32);

U32 f6925(wasmcomponentldInstance*,U32);

U32 f6926(wasmcomponentldInstance*,U32);

U32 f6927(wasmcomponentldInstance*,U32);

U32 f6928(wasmcomponentldInstance*,U32);

U32 f6929(wasmcomponentldInstance*,U32);

U32 f6930(wasmcomponentldInstance*,U32);

U32 f6931(wasmcomponentldInstance*,U32);

U32 f6932(wasmcomponentldInstance*,U32);

U32 f6933(wasmcomponentldInstance*,U32);

U32 f6934(wasmcomponentldInstance*,U32);

U32 f6935(wasmcomponentldInstance*,U32);

U32 f6936(wasmcomponentldInstance*,U32);

U32 f6937(wasmcomponentldInstance*,U32);

U32 f6938(wasmcomponentldInstance*,U32);

U32 f6939(wasmcomponentldInstance*,U32);

U32 f6940(wasmcomponentldInstance*,U32);

U32 f6941(wasmcomponentldInstance*,U32);

U32 f6942(wasmcomponentldInstance*,U32);

U32 f6943(wasmcomponentldInstance*,U32);

U32 f6944(wasmcomponentldInstance*,U32);

U32 f6945(wasmcomponentldInstance*,U32);

U32 f6946(wasmcomponentldInstance*,U32);

U32 f6947(wasmcomponentldInstance*,U32);

U32 f6948(wasmcomponentldInstance*,U32);

U32 f6949(wasmcomponentldInstance*,U32);

U32 f6950(wasmcomponentldInstance*,U32);

U32 f6951(wasmcomponentldInstance*,U32);

U32 f6952(wasmcomponentldInstance*,U32);

U32 f6953(wasmcomponentldInstance*,U32);

U32 f6954(wasmcomponentldInstance*,U32);

U32 f6955(wasmcomponentldInstance*,U32);

U32 f6956(wasmcomponentldInstance*,U32,U32);

U32 f6957(wasmcomponentldInstance*,U32,U32);

U32 f6958(wasmcomponentldInstance*,U32,U32,U32);

U32 f6959(wasmcomponentldInstance*,U32,U32,U32);

U32 f6960(wasmcomponentldInstance*,U32,U32,U32);

U32 f6961(wasmcomponentldInstance*,U32,U32,U32);

U32 f6962(wasmcomponentldInstance*,U32,U32);

U32 f6963(wasmcomponentldInstance*,U32,U32);

U32 f6964(wasmcomponentldInstance*,U32,U32,U32);

U32 f6965(wasmcomponentldInstance*,U32,U32,U32);

U32 f6966(wasmcomponentldInstance*,U32,U32,U32);

U32 f6967(wasmcomponentldInstance*,U32,U32);

U32 f6968(wasmcomponentldInstance*,U32,U32);

U32 f6969(wasmcomponentldInstance*,U32,U32);

U32 f6970(wasmcomponentldInstance*,U32,U32);

U32 f6971(wasmcomponentldInstance*,U32);

U32 f6972(wasmcomponentldInstance*,U32,U32);

U32 f6973(wasmcomponentldInstance*,U32,U32,U32);

U32 f6974(wasmcomponentldInstance*,U32,U32,U32);

U32 f6975(wasmcomponentldInstance*,U32,U32,U32);

U32 f6976(wasmcomponentldInstance*,U32,U32);

U32 f6977(wasmcomponentldInstance*,U32,U32);

U32 f6978(wasmcomponentldInstance*,U32,U32);

U32 f6979(wasmcomponentldInstance*,U32,U32);

U32 f6980(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6981(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6982(wasmcomponentldInstance*,U32);

U32 f6983(wasmcomponentldInstance*,U32);

U32 f6984(wasmcomponentldInstance*,U32);

U32 f6985(wasmcomponentldInstance*,U32);

U32 f6986(wasmcomponentldInstance*,U32);

U32 f6987(wasmcomponentldInstance*,U32,U32);

U32 f6988(wasmcomponentldInstance*,U32,U32);

U32 f6989(wasmcomponentldInstance*,U32,U32);

U32 f6990(wasmcomponentldInstance*,U32,U32);

U32 f6991(wasmcomponentldInstance*,U32,U32);

U32 f6992(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6993(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f6994(wasmcomponentldInstance*,U32);

U32 f6995(wasmcomponentldInstance*,U32);

U32 f6996(wasmcomponentldInstance*,U32);

U32 f6997(wasmcomponentldInstance*,U32);

U32 f6998(wasmcomponentldInstance*,U32);

U32 f6999(wasmcomponentldInstance*,U32);

U32 f7000(wasmcomponentldInstance*,U32);

U32 f7001(wasmcomponentldInstance*,U32);

U32 f7002(wasmcomponentldInstance*,U32,U32,U32);

U32 f7003(wasmcomponentldInstance*,U32,U32);

U32 f7004(wasmcomponentldInstance*,U32,U32,U32);

U32 f7005(wasmcomponentldInstance*,U32,U32);

U32 f7006(wasmcomponentldInstance*,U32,U32,U32);

U32 f7007(wasmcomponentldInstance*,U32,U32);

U32 f7008(wasmcomponentldInstance*,U32,U32,U32);

U32 f7009(wasmcomponentldInstance*,U32,U32,U32);

U32 f7010(wasmcomponentldInstance*,U32,U32);

U32 f7011(wasmcomponentldInstance*,U32);

U32 f7012(wasmcomponentldInstance*,U32,U32);

U32 f7013(wasmcomponentldInstance*,U32,U32);

U32 f7014(wasmcomponentldInstance*,U32,U32);

U32 f7015(wasmcomponentldInstance*,U32,U32);

U32 f7016(wasmcomponentldInstance*,U32,U32);

U32 f7017(wasmcomponentldInstance*,U32,U32);

U32 f7018(wasmcomponentldInstance*,U32,U32);

U32 f7019(wasmcomponentldInstance*,U32,U32,U32);

U32 f7020(wasmcomponentldInstance*,U32,U32);

U32 f7021(wasmcomponentldInstance*,U32,U32);

U32 f7022(wasmcomponentldInstance*,U32,U32);

U32 f7023(wasmcomponentldInstance*,U32,U32);

U32 f7024(wasmcomponentldInstance*,U32);

U32 f7025(wasmcomponentldInstance*,U32,U32);

U32 f7026(wasmcomponentldInstance*,U32,U32);

U32 f7027(wasmcomponentldInstance*,U32,U32);

U32 f7028(wasmcomponentldInstance*,U32,U32);

U32 f7029(wasmcomponentldInstance*,U32,U32);

U32 f7030(wasmcomponentldInstance*,U32,U32);

U32 f7031(wasmcomponentldInstance*,U32,U32);

U32 f7032(wasmcomponentldInstance*,U32,U32);

U32 f7033(wasmcomponentldInstance*,U32,U32);

U32 f7034(wasmcomponentldInstance*,U32,U32);

U32 f7035(wasmcomponentldInstance*,U32,U32);

U32 f7036(wasmcomponentldInstance*,U32,U32);

U32 f7037(wasmcomponentldInstance*,U32,U32);

U32 f7038(wasmcomponentldInstance*,U32,U32);

U32 f7039(wasmcomponentldInstance*,U32,U32);

U32 f7040(wasmcomponentldInstance*,U32,U32);

U32 f7041(wasmcomponentldInstance*,U32,U32);

U32 f7042(wasmcomponentldInstance*,U32,U32);

U32 f7043(wasmcomponentldInstance*,U32,U32);

U32 f7044(wasmcomponentldInstance*,U32,U32);

U32 f7045(wasmcomponentldInstance*,U32,U32);

U32 f7046(wasmcomponentldInstance*,U32,U32);

U32 f7047(wasmcomponentldInstance*,U32,U32);

U32 f7048(wasmcomponentldInstance*,U32,U32);

U32 f7049(wasmcomponentldInstance*,U32,U32);

U32 f7050(wasmcomponentldInstance*,U32,U32);

U32 f7051(wasmcomponentldInstance*,U32,U32);

U32 f7052(wasmcomponentldInstance*,U32,U32);

U32 f7053(wasmcomponentldInstance*,U32,U32);

U32 f7054(wasmcomponentldInstance*,U32,U32);

U32 f7055(wasmcomponentldInstance*,U32,U32);

U32 f7056(wasmcomponentldInstance*,U32,U32);

U32 f7057(wasmcomponentldInstance*,U32,U32);

U32 f7058(wasmcomponentldInstance*,U32,U32);

U32 f7059(wasmcomponentldInstance*,U32,U32);

U32 f7060(wasmcomponentldInstance*,U32,U32);

U32 f7061(wasmcomponentldInstance*,U32,U32);

U32 f7062(wasmcomponentldInstance*,U32,U32);

U32 f7063(wasmcomponentldInstance*,U32,U32);

U32 f7064(wasmcomponentldInstance*,U32,U32);

U32 f7065(wasmcomponentldInstance*,U32,U32);

U32 f7066(wasmcomponentldInstance*,U32,U32);

U32 f7067(wasmcomponentldInstance*,U32,U32);

U32 f7068(wasmcomponentldInstance*,U32,U32);

U32 f7069(wasmcomponentldInstance*,U32,U32);

U32 f7070(wasmcomponentldInstance*,U32,U32);

U32 f7071(wasmcomponentldInstance*,U32,U32);

U32 f7072(wasmcomponentldInstance*,U32,U32);

U32 f7073(wasmcomponentldInstance*,U32,U32);

U32 f7074(wasmcomponentldInstance*,U32,U32);

U32 f7075(wasmcomponentldInstance*,U32,U32);

U32 f7076(wasmcomponentldInstance*,U32,U32);

U32 f7077(wasmcomponentldInstance*,U32,U32);

U32 f7078(wasmcomponentldInstance*,U32,U32);

U32 f7079(wasmcomponentldInstance*,U32,U32);

U32 f7080(wasmcomponentldInstance*,U32,U32);

U32 f7081(wasmcomponentldInstance*,U32,U32);

U32 f7082(wasmcomponentldInstance*,U32,U32);

U32 f7083(wasmcomponentldInstance*,U32,U32);

U32 f7084(wasmcomponentldInstance*,U32,U32);

U32 f7085(wasmcomponentldInstance*,U32,U32);

U32 f7086(wasmcomponentldInstance*,U32,U32);

U32 f7087(wasmcomponentldInstance*,U32,U32);

U32 f7088(wasmcomponentldInstance*,U32,U32);

U32 f7089(wasmcomponentldInstance*,U32);

U32 f7090(wasmcomponentldInstance*,U32,U32);

U32 f7091(wasmcomponentldInstance*,U32,U32);

U32 f7092(wasmcomponentldInstance*,U32,U32);

U32 f7093(wasmcomponentldInstance*,U32,U32);

U32 f7094(wasmcomponentldInstance*,U32);

U32 f7095(wasmcomponentldInstance*,U32,U32,U32);

U32 f7096(wasmcomponentldInstance*,U32,U32,U32);

U32 f7097(wasmcomponentldInstance*,U32,U32,U32);

U32 f7098(wasmcomponentldInstance*,U32,U32,U32);

U32 f7099(wasmcomponentldInstance*,U32,U32,U32);

U32 f7100(wasmcomponentldInstance*,U32,U32,U32);

U32 f7101(wasmcomponentldInstance*,U32,U32,U32);

U32 f7102(wasmcomponentldInstance*,U32,U32,U32);

U32 f7103(wasmcomponentldInstance*,U32,U32,U32);

U32 f7104(wasmcomponentldInstance*,U32,U32,U32);

U32 f7105(wasmcomponentldInstance*,U32,U32,U32);

U32 f7106(wasmcomponentldInstance*,U32,U32,U32);

U32 f7107(wasmcomponentldInstance*,U32,U32,U32);

U32 f7108(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7109(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7110(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7111(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7112(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7113(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7114(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7115(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7116(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7117(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7118(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7119(wasmcomponentldInstance*,U32,U32,U32);

U32 f7120(wasmcomponentldInstance*,U32,U32,U32);

U32 f7121(wasmcomponentldInstance*,U32,U32,U32);

U32 f7122(wasmcomponentldInstance*,U32,U32,U32);

U32 f7123(wasmcomponentldInstance*,U32,U32,U32);

U32 f7124(wasmcomponentldInstance*,U32,U32,U32);

U32 f7125(wasmcomponentldInstance*,U32,U32,U32);

U32 f7126(wasmcomponentldInstance*,U32,U32,U32);

U32 f7127(wasmcomponentldInstance*,U32,U32,U32);

U32 f7128(wasmcomponentldInstance*,U32,U32,U32);

U32 f7129(wasmcomponentldInstance*,U32,U32,U32);

U32 f7130(wasmcomponentldInstance*,U32);

U32 f7131(wasmcomponentldInstance*,U32,U32);

U32 f7132(wasmcomponentldInstance*,U32,U32);

U32 f7133(wasmcomponentldInstance*,U32);

U32 f7134(wasmcomponentldInstance*,U32,U32);

U32 f7135(wasmcomponentldInstance*,U32,U32);

U32 f7136(wasmcomponentldInstance*,U32,U32);

U32 f7137(wasmcomponentldInstance*,U32,U32,U32);

U32 f7138(wasmcomponentldInstance*,U32,U32);

U32 f7139(wasmcomponentldInstance*,U32,U32,U32);

U32 f7140(wasmcomponentldInstance*,U32);

U32 f7141(wasmcomponentldInstance*,U32);

U32 f7142(wasmcomponentldInstance*,U32);

U32 f7143(wasmcomponentldInstance*,U32);

void f7144(wasmcomponentldInstance*,U32,U32);

void f7145(wasmcomponentldInstance*,U32,U32);

void f7146(wasmcomponentldInstance*,U32,U32);

void f7147(wasmcomponentldInstance*,U32,U32);

void f7148(wasmcomponentldInstance*,U32,U32);

void f7149(wasmcomponentldInstance*,U32,U32);

void f7150(wasmcomponentldInstance*,U32);

void f7151(wasmcomponentldInstance*,U32);

void f7152(wasmcomponentldInstance*,U32);

void f7153(wasmcomponentldInstance*,U32);

void f7154(wasmcomponentldInstance*,U32);

void f7155(wasmcomponentldInstance*,U32,U32,U32);

void f7156(wasmcomponentldInstance*,U32,U32,U32);

void f7157(wasmcomponentldInstance*,U32,U32,U32);

void f7158(wasmcomponentldInstance*,U32,U32,U32);

void f7159(wasmcomponentldInstance*,U32,U32,U32);

void f7160(wasmcomponentldInstance*,U32,U32);

void f7161(wasmcomponentldInstance*,U32,U32);

void f7162(wasmcomponentldInstance*,U32,U32);

void f7163(wasmcomponentldInstance*,U32,U32,U32);

void f7164(wasmcomponentldInstance*,U32,U32);

void f7165(wasmcomponentldInstance*,U32,U32,U32);

void f7166(wasmcomponentldInstance*,U32,U32,U32);

void f7167(wasmcomponentldInstance*,U32,U32,U32);

void f7168(wasmcomponentldInstance*,U32,U32,U32);

void f7169(wasmcomponentldInstance*,U32,U32);

void f7170(wasmcomponentldInstance*,U32,U32,U32);

void f7171(wasmcomponentldInstance*,U32,U32,U32);

void f7172(wasmcomponentldInstance*,U32);

void f7173(wasmcomponentldInstance*,U32,U32);

void f7174(wasmcomponentldInstance*,U32,U32);

void f7175(wasmcomponentldInstance*,U32,U32);

void f7176(wasmcomponentldInstance*,U32,U32);

void f7177(wasmcomponentldInstance*,U32,U32);

void f7178(wasmcomponentldInstance*,U32,U32);

void f7179(wasmcomponentldInstance*,U32,U32);

void f7180(wasmcomponentldInstance*,U32,U32);

void f7181(wasmcomponentldInstance*,U32,U32);

U32 f7182(wasmcomponentldInstance*,U32,U32);

void f7183(wasmcomponentldInstance*,U32);

void f7184(wasmcomponentldInstance*,U32);

void f7185(wasmcomponentldInstance*,U32,U32);

void f7186(wasmcomponentldInstance*,U32);

void f7187(wasmcomponentldInstance*,U32);

void f7188(wasmcomponentldInstance*,U64,U32);

void f7189(wasmcomponentldInstance*,U32,U64);

U32 f7190(wasmcomponentldInstance*,U32,U32);

void f7191(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f7192(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7193(wasmcomponentldInstance*,U32,U32,U32);

void f7194(wasmcomponentldInstance*,U32,U32,U32);

void f7195(wasmcomponentldInstance*,U32,U32,U32);

void f7196(wasmcomponentldInstance*,U32,U32,U32);

void f7197(wasmcomponentldInstance*,U32,U32,U32);

void f7198(wasmcomponentldInstance*,U32,U32,U32);

void f7199(wasmcomponentldInstance*,U32,U32,U32);

void f7200(wasmcomponentldInstance*,U32,U32,U32);

void f7201(wasmcomponentldInstance*,U32,U32,U32);

void f7202(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f7203(wasmcomponentldInstance*,U32,U32,U32);

void f7204(wasmcomponentldInstance*,U32,U32,U32);

void f7205(wasmcomponentldInstance*,U32,U32,U32);

U32 f7206(wasmcomponentldInstance*,U32,U32);

void f7207(wasmcomponentldInstance*,U32,U32,U32);

U32 f7208(wasmcomponentldInstance*,U32,U32);

void f7209(wasmcomponentldInstance*,U32,U32,U32);

void f7210(wasmcomponentldInstance*,U32,U32,U32);

void f7211(wasmcomponentldInstance*,U32,U32,U32);

void f7212(wasmcomponentldInstance*,U32,U32,U32);

void f7213(wasmcomponentldInstance*,U32,U32,U32);

void f7214(wasmcomponentldInstance*,U32,U32,U32);

void f7215(wasmcomponentldInstance*,U32,U32,U32);

void f7216(wasmcomponentldInstance*,U32,U32,U32);

void f7217(wasmcomponentldInstance*,U32,U32,U32);

void f7218(wasmcomponentldInstance*,U32,U32);

void f7219(wasmcomponentldInstance*,U32,U32);

void f7220(wasmcomponentldInstance*,U32,U32);

void f7221(wasmcomponentldInstance*,U32,U32);

void f7222(wasmcomponentldInstance*,U32,U32);

void f7223(wasmcomponentldInstance*,U32,U32);

U32 f7224(wasmcomponentldInstance*,U32,U32);

void f7225(wasmcomponentldInstance*,U32,U32);

void f7226(wasmcomponentldInstance*,U32,U32);

void f7227(wasmcomponentldInstance*,U32,U32);

void f7228(wasmcomponentldInstance*,U32,U32);

void f7229(wasmcomponentldInstance*,U32,U32);

void f7230(wasmcomponentldInstance*,U32,U32);

void f7231(wasmcomponentldInstance*,U32,U32);

void f7232(wasmcomponentldInstance*,U32,U32);

void f7233(wasmcomponentldInstance*,U32,U32);

void f7234(wasmcomponentldInstance*,U32,U32);

void f7235(wasmcomponentldInstance*,U32,U32);

void f7236(wasmcomponentldInstance*,U32,U32);

void f7237(wasmcomponentldInstance*,U32,U32);

void f7238(wasmcomponentldInstance*,U32,U32);

void f7239(wasmcomponentldInstance*,U32,U32);

void f7240(wasmcomponentldInstance*,U32,U32);

void f7241(wasmcomponentldInstance*,U32,U32);

void f7242(wasmcomponentldInstance*,U32,U32);

void f7243(wasmcomponentldInstance*,U32,U32);

void f7244(wasmcomponentldInstance*,U32,U32);

void f7245(wasmcomponentldInstance*,U32,U32);

void f7246(wasmcomponentldInstance*,U32,U32,U32);

void f7247(wasmcomponentldInstance*,U32,U32);

void f7248(wasmcomponentldInstance*,U32,U32);

void f7249(wasmcomponentldInstance*,U32,U32);

U32 f7250(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f7251(wasmcomponentldInstance*,U32);

U32 f7252(wasmcomponentldInstance*,U32,U32);

U32 f7253(wasmcomponentldInstance*,U32,U32);

void f7254(wasmcomponentldInstance*,U32,U32);

void f7255(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f7256(wasmcomponentldInstance*,U32,U32);

U32 f7257(wasmcomponentldInstance*,U32,U32,U32);

void f7258(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7259(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7260(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7261(wasmcomponentldInstance*,U32,U32);

void f7262(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7263(wasmcomponentldInstance*,U32,U32);

U32 f7264(wasmcomponentldInstance*,U32,U32);

U32 f7265(wasmcomponentldInstance*,U32,U32);

U32 f7266(wasmcomponentldInstance*,U32);

void f7267(wasmcomponentldInstance*,U32);

U32 f7268(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7269(wasmcomponentldInstance*,U32,U32);

void f7270(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7271(wasmcomponentldInstance*,U32,U32);

void f7272(wasmcomponentldInstance*,U32,U32);

void f7273(wasmcomponentldInstance*,U32,U32);

void f7274(wasmcomponentldInstance*,U32,U32);

void f7275(wasmcomponentldInstance*,U32,U32);

void f7276(wasmcomponentldInstance*,U32,U32);

void f7277(wasmcomponentldInstance*,U32,U32);

void f7278(wasmcomponentldInstance*,U32,U32);

void f7279(wasmcomponentldInstance*,U32,U32);

void f7280(wasmcomponentldInstance*,U32,U32);

void f7281(wasmcomponentldInstance*,U32,U32);

void f7282(wasmcomponentldInstance*,U32,U32);

void f7283(wasmcomponentldInstance*,U32,U32);

void f7284(wasmcomponentldInstance*,U32,U32);

void f7285(wasmcomponentldInstance*,U32,U32);

void f7286(wasmcomponentldInstance*,U32,U32);

void f7287(wasmcomponentldInstance*,U32,U32);

void f7288(wasmcomponentldInstance*,U32,U32);

void f7289(wasmcomponentldInstance*,U32,U32);

void f7290(wasmcomponentldInstance*,U32,U32);

void f7291(wasmcomponentldInstance*,U32,U32);

void f7292(wasmcomponentldInstance*,U32,U32);

void f7293(wasmcomponentldInstance*,U32,U32);

void f7294(wasmcomponentldInstance*,U32,U32);

void f7295(wasmcomponentldInstance*,U32,U32);

void f7296(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f7297(wasmcomponentldInstance*,U32,U32);

void f7298(wasmcomponentldInstance*,U32,U32);

void f7299(wasmcomponentldInstance*,U32,U32);

void f7300(wasmcomponentldInstance*,U32,U32);

U32 f7301(wasmcomponentldInstance*,U32,U32,U32);

U32 f7302(wasmcomponentldInstance*,U32,U32,U32);

U32 f7303(wasmcomponentldInstance*,U32,U32,U32);

void f7304(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f7305(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7306(wasmcomponentldInstance*);

U32 f7307(wasmcomponentldInstance*,U32,U32);

U32 f7308(wasmcomponentldInstance*,U32,U32);

U32 f7309(wasmcomponentldInstance*,U32,U32);

U32 f7310(wasmcomponentldInstance*,U32,U32);

U32 f7311(wasmcomponentldInstance*,U32,U32);

U32 f7312(wasmcomponentldInstance*,U32,U32);

U32 f7313(wasmcomponentldInstance*,U32,U32);

U32 f7314(wasmcomponentldInstance*,U32,U32);

U32 f7315(wasmcomponentldInstance*,U32,U32);

U32 f7316(wasmcomponentldInstance*,U32,U32);

U32 f7317(wasmcomponentldInstance*,U32,U32);

U32 f7318(wasmcomponentldInstance*,U32,U32);

U32 f7319(wasmcomponentldInstance*,U32,U32);

U32 f7320(wasmcomponentldInstance*,U32,U32);

U32 f7321(wasmcomponentldInstance*,U32,U32);

U32 f7322(wasmcomponentldInstance*,U32,U32);

U32 f7323(wasmcomponentldInstance*,U32,U32);

U32 f7324(wasmcomponentldInstance*,U32,U32);

U32 f7325(wasmcomponentldInstance*,U32,U32);

U32 f7326(wasmcomponentldInstance*,U32,U32);

U32 f7327(wasmcomponentldInstance*,U32,U32);

U32 f7328(wasmcomponentldInstance*,U32,U32);

U32 f7329(wasmcomponentldInstance*,U32,U32);

U32 f7330(wasmcomponentldInstance*,U32,U32);

U32 f7331(wasmcomponentldInstance*,U32,U32);

U32 f7332(wasmcomponentldInstance*,U32,U32);

U32 f7333(wasmcomponentldInstance*,U32,U32);

U32 f7334(wasmcomponentldInstance*,U32,U32);

U32 f7335(wasmcomponentldInstance*,U32,U32);

U32 f7336(wasmcomponentldInstance*,U32,U32);

U32 f7337(wasmcomponentldInstance*,U32,U32);

U32 f7338(wasmcomponentldInstance*,U32,U32);

U32 f7339(wasmcomponentldInstance*,U32,U32);

U32 f7340(wasmcomponentldInstance*,U32,U32);

U32 f7341(wasmcomponentldInstance*,U32,U32);

U32 f7342(wasmcomponentldInstance*,U32,U32);

U32 f7343(wasmcomponentldInstance*,U32,U32);

U32 f7344(wasmcomponentldInstance*,U32,U32);

void f7345(wasmcomponentldInstance*,U32);

U64 f7346(wasmcomponentldInstance*,U32,U32);

void f7347(wasmcomponentldInstance*,U32,U32,U32);

U64 f7348(wasmcomponentldInstance*,U32,U32,U32);

U64 f7349(wasmcomponentldInstance*,U32,U32);

U64 f7350(wasmcomponentldInstance*,U32,U32,U32);

U64 f7351(wasmcomponentldInstance*,U32,U32);

U64 f7352(wasmcomponentldInstance*,U32,U32);

U64 f7353(wasmcomponentldInstance*,U32,U32);

U64 f7354(wasmcomponentldInstance*,U32,U32);

U64 f7355(wasmcomponentldInstance*,U32,U32);

U64 f7356(wasmcomponentldInstance*,U32,U32);

U32 f7357(wasmcomponentldInstance*,U32,U32);

void f7358(wasmcomponentldInstance*,U32,U32);

U32 f7359(wasmcomponentldInstance*,U32,U32);

void f7360(wasmcomponentldInstance*,U32,U32);

void f7361(wasmcomponentldInstance*,U32,U32);

void f7362(wasmcomponentldInstance*,U32,U32);

void f7363(wasmcomponentldInstance*,U32,U32);

void f7364(wasmcomponentldInstance*,U32,U32);

void f7365(wasmcomponentldInstance*,U32,U32);

void f7366(wasmcomponentldInstance*,U32,U32);

void f7367(wasmcomponentldInstance*,U32,U32);

void f7368(wasmcomponentldInstance*,U32,U32);

void f7369(wasmcomponentldInstance*,U32,U32);

U32 f7370(wasmcomponentldInstance*,U32,U32);

void f7371(wasmcomponentldInstance*,U32,U32);

void f7372(wasmcomponentldInstance*,U32,U32);

void f7373(wasmcomponentldInstance*,U32,U32);

U32 f7374(wasmcomponentldInstance*,U32,U32);

U32 f7375(wasmcomponentldInstance*,U32);

U32 f7376(wasmcomponentldInstance*,U32,U32,U32);

void f7377(wasmcomponentldInstance*,U32,U32,U32);

void f7378(wasmcomponentldInstance*,U32,U32);

void f7379(wasmcomponentldInstance*,U32,U32);

void f7380(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f7381(wasmcomponentldInstance*,U32,U32,U32);

void f7382(wasmcomponentldInstance*,U32,U32,U32);

void f7383(wasmcomponentldInstance*,U32,U32);

void f7384(wasmcomponentldInstance*,U32,U32);

U32 f7385(wasmcomponentldInstance*,U32,U32);

void f7386(wasmcomponentldInstance*,U32,U32,U32);

U32 f7387(wasmcomponentldInstance*,U32,U32);

void f7388(wasmcomponentldInstance*,U32,U32);

void f7389(wasmcomponentldInstance*,U32,U32);

void f7390(wasmcomponentldInstance*,U32,U32,U32);

void f7391(wasmcomponentldInstance*,U32,U32);

void f7392(wasmcomponentldInstance*,U32,U32);

void f7393(wasmcomponentldInstance*,U32,U32);

void f7394(wasmcomponentldInstance*,U32,U32);

U32 f7395(wasmcomponentldInstance*,U32,U32);

void f7396(wasmcomponentldInstance*,U32,U32,U32);

U32 f7397(wasmcomponentldInstance*,U32,U32);

U32 f7398(wasmcomponentldInstance*,U32,U32);

void f7399(wasmcomponentldInstance*,U32);

void f7400(wasmcomponentldInstance*,U32);

void f7401(wasmcomponentldInstance*,U32);

void f7402(wasmcomponentldInstance*,U32);

void f7403(wasmcomponentldInstance*,U32);

void f7404(wasmcomponentldInstance*,U32);

void f7405(wasmcomponentldInstance*,U32);

void f7406(wasmcomponentldInstance*,U32);

void f7407(wasmcomponentldInstance*,U32);

void f7408(wasmcomponentldInstance*,U32);

void f7409(wasmcomponentldInstance*,U32);

void f7410(wasmcomponentldInstance*,U32);

void f7411(wasmcomponentldInstance*,U32);

void f7412(wasmcomponentldInstance*,U32);

void f7413(wasmcomponentldInstance*,U32);

U32 f7414(wasmcomponentldInstance*,U32,U32);

void f7415(wasmcomponentldInstance*,U32);

void f7416(wasmcomponentldInstance*,U32,U32,U32);

void f7417(wasmcomponentldInstance*,U32,U32,U32);

void f7418(wasmcomponentldInstance*,U32,U32,U32);

void f7419(wasmcomponentldInstance*,U32,U32,U32);

void f7420(wasmcomponentldInstance*,U32,U32,U32);

void f7421(wasmcomponentldInstance*,U32,U32,U32);

void f7422(wasmcomponentldInstance*,U32,U32);

void f7423(wasmcomponentldInstance*,U32,U32);

void f7424(wasmcomponentldInstance*,U32,U32);

void f7425(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7426(wasmcomponentldInstance*,U32);

void f7427(wasmcomponentldInstance*,U32,U64);

void f7428(wasmcomponentldInstance*,U32,U32,U32);

void f7429(wasmcomponentldInstance*,U32,U32,U32);

U32 f7430(wasmcomponentldInstance*,U32,U32,U32);

U32 f7431(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f7432(wasmcomponentldInstance*,U32,U32);

U32 f7433(wasmcomponentldInstance*,U32,U32);

U32 f7434(wasmcomponentldInstance*,U32,U32);

U32 f7435(wasmcomponentldInstance*,U32,U32);

U32 f7436(wasmcomponentldInstance*,U32,U32);

U32 f7437(wasmcomponentldInstance*,U32,U32);

U32 f7438(wasmcomponentldInstance*,U32,U32);

U32 f7439(wasmcomponentldInstance*,U32,U32);

U32 f7440(wasmcomponentldInstance*,U32,U32,U32);

U32 f7441(wasmcomponentldInstance*,U32,U32);

U32 f7442(wasmcomponentldInstance*,U32,U32,U32);

U32 f7443(wasmcomponentldInstance*,U32,U32);

U32 f7444(wasmcomponentldInstance*,U32,U32);

void f7445(wasmcomponentldInstance*,U32,U32,U32);

U32 f7446(wasmcomponentldInstance*,U32,U32);

void f7447(wasmcomponentldInstance*,U32,U32);

U32 f7448(wasmcomponentldInstance*,U32,U32);

U32 f7449(wasmcomponentldInstance*,U32,U32);

U32 f7450(wasmcomponentldInstance*,U32,U32);

U32 f7451(wasmcomponentldInstance*,U32,U32);

U32 f7452(wasmcomponentldInstance*,U32,U32);

U32 f7453(wasmcomponentldInstance*,U32,U32);

U32 f7454(wasmcomponentldInstance*,U32,U32);

U32 f7455(wasmcomponentldInstance*,U32,U32,U32);

U32 f7456(wasmcomponentldInstance*,U32,U32);

U32 f7457(wasmcomponentldInstance*,U32,U32);

void f7458(wasmcomponentldInstance*,U32,U32,U32);

U32 f7459(wasmcomponentldInstance*,U32,U32);

U32 f7460(wasmcomponentldInstance*,U32,U32);

U32 f7461(wasmcomponentldInstance*,U32,U32);

U32 f7462(wasmcomponentldInstance*,U32,U32);

U32 f7463(wasmcomponentldInstance*,U32,U32);

U32 f7464(wasmcomponentldInstance*,U32,U32);

U32 f7465(wasmcomponentldInstance*,U32,U32);

U32 f7466(wasmcomponentldInstance*,U32,U32);

U32 f7467(wasmcomponentldInstance*,U32,U32);

U32 f7468(wasmcomponentldInstance*,U32,U32);

U32 f7469(wasmcomponentldInstance*,U32,U32);

U32 f7470(wasmcomponentldInstance*,U32,U32);

U32 f7471(wasmcomponentldInstance*,U32,U32);

U32 f7472(wasmcomponentldInstance*,U32,U32);

U32 f7473(wasmcomponentldInstance*,U32,U32);

U32 f7474(wasmcomponentldInstance*,U32,U32);

U32 f7475(wasmcomponentldInstance*,U32,U32);

U32 f7476(wasmcomponentldInstance*,U32,U32);

U32 f7477(wasmcomponentldInstance*,U32,U32);

U32 f7478(wasmcomponentldInstance*,U32,U32);

U32 f7479(wasmcomponentldInstance*,U32,U32);

U32 f7480(wasmcomponentldInstance*,U32,U32);

U32 f7481(wasmcomponentldInstance*,U32,U32);

U32 f7482(wasmcomponentldInstance*,U32,U32);

U32 f7483(wasmcomponentldInstance*,U32,U32);

U32 f7484(wasmcomponentldInstance*,U32,U32);

U32 f7485(wasmcomponentldInstance*,U32,U32);

U32 f7486(wasmcomponentldInstance*,U32,U32);

U32 f7487(wasmcomponentldInstance*,U32,U32);

U32 f7488(wasmcomponentldInstance*,U32,U32);

U32 f7489(wasmcomponentldInstance*,U32,U32);

void f7490(wasmcomponentldInstance*,U32);

void f7491(wasmcomponentldInstance*,U32);

void f7492(wasmcomponentldInstance*,U32,U32);

void f7493(wasmcomponentldInstance*,U32,U32);

void f7494(wasmcomponentldInstance*,U32,U32);

void f7495(wasmcomponentldInstance*,U32,U32);

void f7496(wasmcomponentldInstance*,U32,U32,U32);

void f7497(wasmcomponentldInstance*,U32,U32);

void f7498(wasmcomponentldInstance*,U32,U32);

void f7499(wasmcomponentldInstance*,U32,U32);

void f7500(wasmcomponentldInstance*,U32,U32);

void f7501(wasmcomponentldInstance*,U32,U32);

void f7502(wasmcomponentldInstance*,U32,U32);

void f7503(wasmcomponentldInstance*,U32,U32);

void f7504(wasmcomponentldInstance*,U32,U32);

void f7505(wasmcomponentldInstance*,U32,U32);

void f7506(wasmcomponentldInstance*,U32,U32);

void f7507(wasmcomponentldInstance*,U32,U32);

void f7508(wasmcomponentldInstance*,U32,U32);

void f7509(wasmcomponentldInstance*,U32,U32);

void f7510(wasmcomponentldInstance*,U32,U32);

void f7511(wasmcomponentldInstance*,U32,U32);

U32 f7512(wasmcomponentldInstance*,U32);

void f7513(wasmcomponentldInstance*,U32,U32);

U32 f7514(wasmcomponentldInstance*,U32);

U32 f7515(wasmcomponentldInstance*,U32);

void f7516(wasmcomponentldInstance*,U32,U32,U32);

void f7517(wasmcomponentldInstance*,U32,U32);

U32 f7518(wasmcomponentldInstance*,U32,U32);

U32 f7519(wasmcomponentldInstance*,U32,U32);

void f7520(wasmcomponentldInstance*,U32,U32);

void f7521(wasmcomponentldInstance*,U32,U32);

void f7522(wasmcomponentldInstance*,U32,U32);

void f7523(wasmcomponentldInstance*,U32,U32);

void f7524(wasmcomponentldInstance*,U32,U32);

U32 f7525(wasmcomponentldInstance*,U32,U32);

U32 f7526(wasmcomponentldInstance*,U32,U32);

U32 f7527(wasmcomponentldInstance*,U32,U32);

U32 f7528(wasmcomponentldInstance*,U32,U32);

void f7529(wasmcomponentldInstance*,U32,U32,U32);

void f7530(wasmcomponentldInstance*,U32,U32,U32);

void f7531(wasmcomponentldInstance*,U32,U32,U32);

void f7532(wasmcomponentldInstance*,U32,U32,U32);

void f7533(wasmcomponentldInstance*,U32,U32,U32);

void f7534(wasmcomponentldInstance*,U32,U32,U32);

void f7535(wasmcomponentldInstance*,U32,U32,U32);

void f7536(wasmcomponentldInstance*,U32,U32,U32);

void f7537(wasmcomponentldInstance*,U32,U32,U32);

void f7538(wasmcomponentldInstance*,U32,U32,U32);

void f7539(wasmcomponentldInstance*,U32,U32,U32);

void f7540(wasmcomponentldInstance*,U32,U32,U32);

void f7541(wasmcomponentldInstance*,U32,U32,U32);

void f7542(wasmcomponentldInstance*,U32,U32,U32);

void f7543(wasmcomponentldInstance*,U32,U32,U32);

void f7544(wasmcomponentldInstance*,U32,U32,U32);

void f7545(wasmcomponentldInstance*,U32,U32,U32);

void f7546(wasmcomponentldInstance*,U32,U32,U32);

void f7547(wasmcomponentldInstance*,U32,U32,U32);

void f7548(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7549(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7550(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7551(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7552(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7553(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7554(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7555(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7556(wasmcomponentldInstance*,U32,U32,U32);

void f7557(wasmcomponentldInstance*,U32,U32,U32);

void f7558(wasmcomponentldInstance*,U32,U32,U32);

void f7559(wasmcomponentldInstance*,U32,U32,U32);

void f7560(wasmcomponentldInstance*,U32,U32,U32);

void f7561(wasmcomponentldInstance*,U32,U32,U32);

void f7562(wasmcomponentldInstance*,U32,U32,U32);

void f7563(wasmcomponentldInstance*,U32,U32,U32);

void f7564(wasmcomponentldInstance*,U32,U32,U32);

void f7565(wasmcomponentldInstance*,U32,U32,U32);

void f7566(wasmcomponentldInstance*,U32,U32,U32);

void f7567(wasmcomponentldInstance*,U32,U32,U32);

void f7568(wasmcomponentldInstance*,U32,U32,U32);

void f7569(wasmcomponentldInstance*,U32,U32,U32);

void f7570(wasmcomponentldInstance*,U32,U32,U32);

void f7571(wasmcomponentldInstance*,U32,U32,U32);

void f7572(wasmcomponentldInstance*,U32,U32);

void f7573(wasmcomponentldInstance*,U32,U32);

void f7574(wasmcomponentldInstance*,U32,U32);

void f7575(wasmcomponentldInstance*,U32,U32);

void f7576(wasmcomponentldInstance*,U32,U32);

void f7577(wasmcomponentldInstance*,U32,U32);

void f7578(wasmcomponentldInstance*,U32,U32);

void f7579(wasmcomponentldInstance*,U32,U32);

void f7580(wasmcomponentldInstance*,U32,U32);

void f7581(wasmcomponentldInstance*,U32,U32);

void f7582(wasmcomponentldInstance*,U32,U32);

void f7583(wasmcomponentldInstance*,U32,U32);

void f7584(wasmcomponentldInstance*,U32,U32);

void f7585(wasmcomponentldInstance*,U32,U32);

void f7586(wasmcomponentldInstance*,U32,U32);

void f7587(wasmcomponentldInstance*,U32,U32);

void f7588(wasmcomponentldInstance*,U32,U32);

void f7589(wasmcomponentldInstance*,U32,U32);

void f7590(wasmcomponentldInstance*,U32,U32);

void f7591(wasmcomponentldInstance*,U32,U32);

void f7592(wasmcomponentldInstance*,U32,U32);

void f7593(wasmcomponentldInstance*,U32,U32);

void f7594(wasmcomponentldInstance*,U32,U32);

void f7595(wasmcomponentldInstance*,U32,U32);

void f7596(wasmcomponentldInstance*,U32,U32);

void f7597(wasmcomponentldInstance*,U32,U32);

void f7598(wasmcomponentldInstance*,U32,U32);

void f7599(wasmcomponentldInstance*,U32,U32);

void f7600(wasmcomponentldInstance*,U32,U32);

void f7601(wasmcomponentldInstance*,U32,U32);

void f7602(wasmcomponentldInstance*,U32,U32);

void f7603(wasmcomponentldInstance*,U32,U32);

void f7604(wasmcomponentldInstance*,U32,U32);

void f7605(wasmcomponentldInstance*,U32,U32);

void f7606(wasmcomponentldInstance*,U32,U32);

void f7607(wasmcomponentldInstance*,U32,U32);

void f7608(wasmcomponentldInstance*,U32,U32);

void f7609(wasmcomponentldInstance*,U32,U32);

void f7610(wasmcomponentldInstance*,U32,U32);

void f7611(wasmcomponentldInstance*,U32,U32);

void f7612(wasmcomponentldInstance*,U32,U32);

void f7613(wasmcomponentldInstance*,U32,U32);

void f7614(wasmcomponentldInstance*,U32,U32);

void f7615(wasmcomponentldInstance*,U32,U32);

void f7616(wasmcomponentldInstance*,U32,U32);

void f7617(wasmcomponentldInstance*,U32,U32);

void f7618(wasmcomponentldInstance*,U32,U32);

void f7619(wasmcomponentldInstance*,U32,U32);

void f7620(wasmcomponentldInstance*,U32,U32);

void f7621(wasmcomponentldInstance*,U32,U32);

void f7622(wasmcomponentldInstance*,U32,U32);

void f7623(wasmcomponentldInstance*,U32,U32);

void f7624(wasmcomponentldInstance*,U32,U32);

void f7625(wasmcomponentldInstance*,U32,U32);

void f7626(wasmcomponentldInstance*,U32,U32);

void f7627(wasmcomponentldInstance*,U32,U32);

void f7628(wasmcomponentldInstance*,U32,U32);

void f7629(wasmcomponentldInstance*,U32,U32);

void f7630(wasmcomponentldInstance*,U32,U32);

void f7631(wasmcomponentldInstance*,U32,U32);

void f7632(wasmcomponentldInstance*,U32,U32);

void f7633(wasmcomponentldInstance*,U32,U32);

void f7634(wasmcomponentldInstance*,U32,U32);

void f7635(wasmcomponentldInstance*,U32,U32);

void f7636(wasmcomponentldInstance*,U32,U32);

void f7637(wasmcomponentldInstance*,U32,U32);

void f7638(wasmcomponentldInstance*,U32,U32);

void f7639(wasmcomponentldInstance*,U32,U32);

void f7640(wasmcomponentldInstance*,U32,U32);

void f7641(wasmcomponentldInstance*,U32,U32);

void f7642(wasmcomponentldInstance*,U32,U32);

void f7643(wasmcomponentldInstance*,U32,U32);

void f7644(wasmcomponentldInstance*,U32,U32);

void f7645(wasmcomponentldInstance*,U32,U32);

void f7646(wasmcomponentldInstance*,U32,U32);

void f7647(wasmcomponentldInstance*,U32,U32);

void f7648(wasmcomponentldInstance*,U32,U32);

void f7649(wasmcomponentldInstance*,U32,U32);

void f7650(wasmcomponentldInstance*,U32,U32);

void f7651(wasmcomponentldInstance*,U32,U32);

void f7652(wasmcomponentldInstance*,U32,U32);

void f7653(wasmcomponentldInstance*,U32,U32);

void f7654(wasmcomponentldInstance*,U32,U32);

void f7655(wasmcomponentldInstance*,U32,U32);

void f7656(wasmcomponentldInstance*,U32,U32);

void f7657(wasmcomponentldInstance*,U32,U32);

void f7658(wasmcomponentldInstance*,U32,U32);

void f7659(wasmcomponentldInstance*,U32,U32);

void f7660(wasmcomponentldInstance*,U32,U32);

void f7661(wasmcomponentldInstance*,U32,U32);

void f7662(wasmcomponentldInstance*,U32,U32);

void f7663(wasmcomponentldInstance*,U32,U32);

void f7664(wasmcomponentldInstance*,U32,U32);

void f7665(wasmcomponentldInstance*,U32,U32);

void f7666(wasmcomponentldInstance*,U32,U32);

void f7667(wasmcomponentldInstance*,U32,U32);

void f7668(wasmcomponentldInstance*,U32,U32);

void f7669(wasmcomponentldInstance*,U32,U32);

void f7670(wasmcomponentldInstance*,U32,U32);

void f7671(wasmcomponentldInstance*,U32,U32);

void f7672(wasmcomponentldInstance*,U32,U32);

void f7673(wasmcomponentldInstance*,U32,U32);

void f7674(wasmcomponentldInstance*,U32,U32);

void f7675(wasmcomponentldInstance*,U32,U32);

void f7676(wasmcomponentldInstance*,U32,U32);

void f7677(wasmcomponentldInstance*,U32,U32);

void f7678(wasmcomponentldInstance*,U32,U32);

void f7679(wasmcomponentldInstance*,U32,U32);

void f7680(wasmcomponentldInstance*,U32,U32);

void f7681(wasmcomponentldInstance*,U32,U32);

void f7682(wasmcomponentldInstance*,U32,U32);

void f7683(wasmcomponentldInstance*,U32,U32);

void f7684(wasmcomponentldInstance*,U32,U32);

void f7685(wasmcomponentldInstance*,U32,U32);

void f7686(wasmcomponentldInstance*,U32,U32);

void f7687(wasmcomponentldInstance*,U32,U32);

void f7688(wasmcomponentldInstance*,U32,U32);

void f7689(wasmcomponentldInstance*,U32,U32);

void f7690(wasmcomponentldInstance*,U32,U32);

void f7691(wasmcomponentldInstance*,U32,U32);

void f7692(wasmcomponentldInstance*,U32,U32);

void f7693(wasmcomponentldInstance*,U32,U32);

void f7694(wasmcomponentldInstance*,U32,U32);

void f7695(wasmcomponentldInstance*,U32,U32);

void f7696(wasmcomponentldInstance*,U32,U32);

void f7697(wasmcomponentldInstance*,U32,U32);

void f7698(wasmcomponentldInstance*,U32,U32);

void f7699(wasmcomponentldInstance*,U32,U32);

void f7700(wasmcomponentldInstance*,U32,U32);

void f7701(wasmcomponentldInstance*,U32,U32);

void f7702(wasmcomponentldInstance*,U32,U32);

void f7703(wasmcomponentldInstance*,U32,U32);

void f7704(wasmcomponentldInstance*,U32,U32);

void f7705(wasmcomponentldInstance*,U32,U32);

void f7706(wasmcomponentldInstance*,U32,U32);

void f7707(wasmcomponentldInstance*,U32,U32);

void f7708(wasmcomponentldInstance*,U32,U32);

void f7709(wasmcomponentldInstance*,U32,U32);

void f7710(wasmcomponentldInstance*,U32,U32);

void f7711(wasmcomponentldInstance*,U32,U32);

void f7712(wasmcomponentldInstance*,U32,U32);

void f7713(wasmcomponentldInstance*,U32,U32);

void f7714(wasmcomponentldInstance*,U32,U32);

void f7715(wasmcomponentldInstance*,U32,U32);

void f7716(wasmcomponentldInstance*,U32,U32);

void f7717(wasmcomponentldInstance*,U32,U32);

void f7718(wasmcomponentldInstance*,U32,U32);

void f7719(wasmcomponentldInstance*,U32,U32);

void f7720(wasmcomponentldInstance*,U32,U32);

void f7721(wasmcomponentldInstance*,U32,U32);

void f7722(wasmcomponentldInstance*,U32,U32);

void f7723(wasmcomponentldInstance*,U32,U32);

void f7724(wasmcomponentldInstance*,U32,U32);

void f7725(wasmcomponentldInstance*,U32,U32);

void f7726(wasmcomponentldInstance*,U32,U32);

void f7727(wasmcomponentldInstance*,U32,U32);

void f7728(wasmcomponentldInstance*,U32,U32);

void f7729(wasmcomponentldInstance*,U32,U32);

void f7730(wasmcomponentldInstance*,U32,U32);

void f7731(wasmcomponentldInstance*,U32,U32);

void f7732(wasmcomponentldInstance*,U32,U32);

void f7733(wasmcomponentldInstance*,U32,U32);

void f7734(wasmcomponentldInstance*,U32,U32);

void f7735(wasmcomponentldInstance*,U32,U32);

void f7736(wasmcomponentldInstance*,U32,U32);

void f7737(wasmcomponentldInstance*,U32,U32);

void f7738(wasmcomponentldInstance*,U32,U32);

void f7739(wasmcomponentldInstance*,U32,U32);

void f7740(wasmcomponentldInstance*,U32,U32);

void f7741(wasmcomponentldInstance*,U32,U32);

void f7742(wasmcomponentldInstance*,U32,U32);

void f7743(wasmcomponentldInstance*,U32,U32);

void f7744(wasmcomponentldInstance*,U32,U32);

void f7745(wasmcomponentldInstance*,U32,U32);

void f7746(wasmcomponentldInstance*,U32,U32);

void f7747(wasmcomponentldInstance*,U32,U32);

void f7748(wasmcomponentldInstance*,U32,U32);

void f7749(wasmcomponentldInstance*,U32,U32);

void f7750(wasmcomponentldInstance*,U32,U32);

void f7751(wasmcomponentldInstance*,U32,U32);

void f7752(wasmcomponentldInstance*,U32,U32);

void f7753(wasmcomponentldInstance*,U32,U32);

void f7754(wasmcomponentldInstance*,U32,U32);

void f7755(wasmcomponentldInstance*,U32,U32);

void f7756(wasmcomponentldInstance*,U32,U32);

void f7757(wasmcomponentldInstance*,U32,U32);

void f7758(wasmcomponentldInstance*,U32,U32);

void f7759(wasmcomponentldInstance*,U32,U32);

void f7760(wasmcomponentldInstance*,U32,U32);

void f7761(wasmcomponentldInstance*,U32,U32);

void f7762(wasmcomponentldInstance*,U32,U32);

void f7763(wasmcomponentldInstance*,U32,U32);

void f7764(wasmcomponentldInstance*,U32,U32);

void f7765(wasmcomponentldInstance*,U32,U32);

void f7766(wasmcomponentldInstance*,U32,U32);

void f7767(wasmcomponentldInstance*,U32,U32);

void f7768(wasmcomponentldInstance*,U32,U32);

void f7769(wasmcomponentldInstance*,U32,U32);

void f7770(wasmcomponentldInstance*,U32,U32);

void f7771(wasmcomponentldInstance*,U32,U32);

void f7772(wasmcomponentldInstance*,U32,U32);

void f7773(wasmcomponentldInstance*,U32,U32);

void f7774(wasmcomponentldInstance*,U32,U32);

void f7775(wasmcomponentldInstance*,U32,U32);

void f7776(wasmcomponentldInstance*,U32,U32);

void f7777(wasmcomponentldInstance*,U32,U32);

void f7778(wasmcomponentldInstance*,U32,U32);

void f7779(wasmcomponentldInstance*,U32,U32);

void f7780(wasmcomponentldInstance*,U32,U32);

void f7781(wasmcomponentldInstance*,U32,U32);

void f7782(wasmcomponentldInstance*,U32,U32);

void f7783(wasmcomponentldInstance*,U32,U32);

void f7784(wasmcomponentldInstance*,U32,U32);

void f7785(wasmcomponentldInstance*,U32,U32);

void f7786(wasmcomponentldInstance*,U32,U32);

void f7787(wasmcomponentldInstance*,U32,U32);

void f7788(wasmcomponentldInstance*,U32,U32);

void f7789(wasmcomponentldInstance*,U32,U32);

void f7790(wasmcomponentldInstance*,U32,U32);

void f7791(wasmcomponentldInstance*,U32,U32);

void f7792(wasmcomponentldInstance*,U32,U32,U32);

void f7793(wasmcomponentldInstance*,U32,U32,U32);

void f7794(wasmcomponentldInstance*,U32,U32,U32);

void f7795(wasmcomponentldInstance*,U32,U32);

void f7796(wasmcomponentldInstance*,U32,U32);

void f7797(wasmcomponentldInstance*,U32,U32,U32);

void f7798(wasmcomponentldInstance*,U32,U32,U32);

void f7799(wasmcomponentldInstance*,U32,U32,U32);

void f7800(wasmcomponentldInstance*,U32,U32);

void f7801(wasmcomponentldInstance*,U32,U32,U32);

void f7802(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7803(wasmcomponentldInstance*,U32,U32);

void f7804(wasmcomponentldInstance*,U32,U32);

void f7805(wasmcomponentldInstance*,U32,U32,U32);

void f7806(wasmcomponentldInstance*,U32,U32,U32);

void f7807(wasmcomponentldInstance*,U32,U32,U32);

void f7808(wasmcomponentldInstance*,U32,U32,U32);

void f7809(wasmcomponentldInstance*,U32,U32,U32);

void f7810(wasmcomponentldInstance*,U32,U32,U32);

void f7811(wasmcomponentldInstance*,U32,U32,U32);

void f7812(wasmcomponentldInstance*,U32,U32,U32);

void f7813(wasmcomponentldInstance*,U32,U32,U32);

void f7814(wasmcomponentldInstance*,U32,U32,U32);

void f7815(wasmcomponentldInstance*,U32,U32,U32);

void f7816(wasmcomponentldInstance*,U32,U32,U32);

void f7817(wasmcomponentldInstance*,U32,U32,U32);

void f7818(wasmcomponentldInstance*,U32,U32,U32);

void f7819(wasmcomponentldInstance*,U32,U32,U32);

void f7820(wasmcomponentldInstance*,U32,U32,U32);

void f7821(wasmcomponentldInstance*,U32,U32,U32);

void f7822(wasmcomponentldInstance*,U32,U32,U32);

void f7823(wasmcomponentldInstance*,U32,U32,U32);

void f7824(wasmcomponentldInstance*,U32,U32,U32);

void f7825(wasmcomponentldInstance*,U32,U32,U32);

void f7826(wasmcomponentldInstance*,U32,U32,U32);

void f7827(wasmcomponentldInstance*,U32,U32,U32);

void f7828(wasmcomponentldInstance*,U32,U32,U32);

void f7829(wasmcomponentldInstance*,U32,U32,U32);

void f7830(wasmcomponentldInstance*,U32,U32,U32);

void f7831(wasmcomponentldInstance*,U32,U32,U32);

void f7832(wasmcomponentldInstance*,U32,U32,U32);

void f7833(wasmcomponentldInstance*,U32,U32,U32);

void f7834(wasmcomponentldInstance*,U32,U32,U32);

void f7835(wasmcomponentldInstance*,U32,U32,U32);

void f7836(wasmcomponentldInstance*,U32,U32,U64);

void f7837(wasmcomponentldInstance*,U32,U32,U32);

void f7838(wasmcomponentldInstance*,U32,U32,U64);

void f7839(wasmcomponentldInstance*,U32,U32);

void f7840(wasmcomponentldInstance*,U32,U32);

void f7841(wasmcomponentldInstance*,U32,U32);

void f7842(wasmcomponentldInstance*,U32,U32);

void f7843(wasmcomponentldInstance*,U32,U32);

void f7844(wasmcomponentldInstance*,U32,U32);

void f7845(wasmcomponentldInstance*,U32,U32);

void f7846(wasmcomponentldInstance*,U32,U32);

void f7847(wasmcomponentldInstance*,U32,U32);

void f7848(wasmcomponentldInstance*,U32,U32);

void f7849(wasmcomponentldInstance*,U32,U32);

void f7850(wasmcomponentldInstance*,U32,U32);

void f7851(wasmcomponentldInstance*,U32,U32);

void f7852(wasmcomponentldInstance*,U32,U32);

void f7853(wasmcomponentldInstance*,U32,U32);

void f7854(wasmcomponentldInstance*,U32,U32);

void f7855(wasmcomponentldInstance*,U32,U32);

void f7856(wasmcomponentldInstance*,U32,U32);

void f7857(wasmcomponentldInstance*,U32,U32);

void f7858(wasmcomponentldInstance*,U32,U32);

void f7859(wasmcomponentldInstance*,U32,U32);

void f7860(wasmcomponentldInstance*,U32,U32);

void f7861(wasmcomponentldInstance*,U32,U32);

void f7862(wasmcomponentldInstance*,U32,U32);

void f7863(wasmcomponentldInstance*,U32,U32);

void f7864(wasmcomponentldInstance*,U32,U32);

void f7865(wasmcomponentldInstance*,U32,U32);

void f7866(wasmcomponentldInstance*,U32,U32);

void f7867(wasmcomponentldInstance*,U32,U32);

void f7868(wasmcomponentldInstance*,U32,U32);

void f7869(wasmcomponentldInstance*,U32,U32);

void f7870(wasmcomponentldInstance*,U32,U32);

void f7871(wasmcomponentldInstance*,U32,U32);

void f7872(wasmcomponentldInstance*,U32,U32);

void f7873(wasmcomponentldInstance*,U32,U32);

void f7874(wasmcomponentldInstance*,U32,U32);

void f7875(wasmcomponentldInstance*,U32,U32);

void f7876(wasmcomponentldInstance*,U32,U32);

void f7877(wasmcomponentldInstance*,U32,U32);

void f7878(wasmcomponentldInstance*,U32,U32);

void f7879(wasmcomponentldInstance*,U32,U32);

void f7880(wasmcomponentldInstance*,U32,U32);

void f7881(wasmcomponentldInstance*,U32,U32);

void f7882(wasmcomponentldInstance*,U32,U32);

void f7883(wasmcomponentldInstance*,U32,U32);

void f7884(wasmcomponentldInstance*,U32,U32);

void f7885(wasmcomponentldInstance*,U32,U32);

void f7886(wasmcomponentldInstance*,U32,U32);

void f7887(wasmcomponentldInstance*,U32,U32);

void f7888(wasmcomponentldInstance*,U32,U32);

void f7889(wasmcomponentldInstance*,U32,U32);

void f7890(wasmcomponentldInstance*,U32,U32);

void f7891(wasmcomponentldInstance*,U32,U32);

void f7892(wasmcomponentldInstance*,U32,U32);

void f7893(wasmcomponentldInstance*,U32,U32);

void f7894(wasmcomponentldInstance*,U32,U32);

void f7895(wasmcomponentldInstance*,U32,U32);

void f7896(wasmcomponentldInstance*,U32,U32);

void f7897(wasmcomponentldInstance*,U32,U32);

void f7898(wasmcomponentldInstance*,U32,U32);

void f7899(wasmcomponentldInstance*,U32,U32);

void f7900(wasmcomponentldInstance*,U32,U32);

void f7901(wasmcomponentldInstance*,U32,U32);

void f7902(wasmcomponentldInstance*,U32,U32);

void f7903(wasmcomponentldInstance*,U32,U32);

void f7904(wasmcomponentldInstance*,U32,U32);

void f7905(wasmcomponentldInstance*,U32,U32);

void f7906(wasmcomponentldInstance*,U32,U32);

void f7907(wasmcomponentldInstance*,U32,U32);

void f7908(wasmcomponentldInstance*,U32,U32);

void f7909(wasmcomponentldInstance*,U32,U32);

void f7910(wasmcomponentldInstance*,U32,U32);

void f7911(wasmcomponentldInstance*,U32,U32);

void f7912(wasmcomponentldInstance*,U32,U32);

void f7913(wasmcomponentldInstance*,U32,U32);

void f7914(wasmcomponentldInstance*,U32,U32);

void f7915(wasmcomponentldInstance*,U32,U32);

void f7916(wasmcomponentldInstance*,U32,U32);

void f7917(wasmcomponentldInstance*,U32,U32);

void f7918(wasmcomponentldInstance*,U32,U32);

void f7919(wasmcomponentldInstance*,U32,U32);

void f7920(wasmcomponentldInstance*,U32,U32);

void f7921(wasmcomponentldInstance*,U32,U32);

void f7922(wasmcomponentldInstance*,U32,U32);

void f7923(wasmcomponentldInstance*,U32,U32);

void f7924(wasmcomponentldInstance*,U32,U32);

void f7925(wasmcomponentldInstance*,U32,U32);

void f7926(wasmcomponentldInstance*,U32,U32);

void f7927(wasmcomponentldInstance*,U32,U32);

void f7928(wasmcomponentldInstance*,U32,U32);

void f7929(wasmcomponentldInstance*,U32,U32);

void f7930(wasmcomponentldInstance*,U32,U32);

void f7931(wasmcomponentldInstance*,U32,U32);

void f7932(wasmcomponentldInstance*,U32,U32);

void f7933(wasmcomponentldInstance*,U32,U32);

void f7934(wasmcomponentldInstance*,U32,U32);

void f7935(wasmcomponentldInstance*,U32,U32);

void f7936(wasmcomponentldInstance*,U32,U32);

void f7937(wasmcomponentldInstance*,U32,U32);

void f7938(wasmcomponentldInstance*,U32,U32);

void f7939(wasmcomponentldInstance*,U32,U32);

void f7940(wasmcomponentldInstance*,U32,U32);

void f7941(wasmcomponentldInstance*,U32,U32);

void f7942(wasmcomponentldInstance*,U32,U32);

void f7943(wasmcomponentldInstance*,U32,U32);

void f7944(wasmcomponentldInstance*,U32,U32);

void f7945(wasmcomponentldInstance*,U32,U32);

void f7946(wasmcomponentldInstance*,U32,U32);

void f7947(wasmcomponentldInstance*,U32,U32);

void f7948(wasmcomponentldInstance*,U32,U32);

void f7949(wasmcomponentldInstance*,U32,U32);

void f7950(wasmcomponentldInstance*,U32,U32);

void f7951(wasmcomponentldInstance*,U32,U32);

void f7952(wasmcomponentldInstance*,U32,U32);

void f7953(wasmcomponentldInstance*,U32,U32);

void f7954(wasmcomponentldInstance*,U32,U32);

void f7955(wasmcomponentldInstance*,U32,U32);

void f7956(wasmcomponentldInstance*,U32,U32);

void f7957(wasmcomponentldInstance*,U32,U32);

void f7958(wasmcomponentldInstance*,U32,U32);

void f7959(wasmcomponentldInstance*,U32,U32);

void f7960(wasmcomponentldInstance*,U32,U32);

void f7961(wasmcomponentldInstance*,U32,U32);

void f7962(wasmcomponentldInstance*,U32,U32);

void f7963(wasmcomponentldInstance*,U32,U32);

void f7964(wasmcomponentldInstance*,U32,U32);

void f7965(wasmcomponentldInstance*,U32,U32);

void f7966(wasmcomponentldInstance*,U32,U32);

void f7967(wasmcomponentldInstance*,U32,U32);

void f7968(wasmcomponentldInstance*,U32,U32,U32);

void f7969(wasmcomponentldInstance*,U32,U32,U32);

void f7970(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7971(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7972(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7973(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7974(wasmcomponentldInstance*,U32,U32,U32);

void f7975(wasmcomponentldInstance*,U32,U32,U32);

void f7976(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7977(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7978(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7979(wasmcomponentldInstance*,U32,U32,U32);

void f7980(wasmcomponentldInstance*,U32,U32,U32);

void f7981(wasmcomponentldInstance*,U32,U32,U32);

void f7982(wasmcomponentldInstance*,U32,U32,U32);

void f7983(wasmcomponentldInstance*,U32,U32);

void f7984(wasmcomponentldInstance*,U32,U32,U32);

void f7985(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7986(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7987(wasmcomponentldInstance*,U32,U32,U32,U32);

void f7988(wasmcomponentldInstance*,U32,U32,U32);

void f7989(wasmcomponentldInstance*,U32,U32,U32);

void f7990(wasmcomponentldInstance*,U32,U32,U32);

void f7991(wasmcomponentldInstance*,U32,U32,U32);

void f7992(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f7993(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f7994(wasmcomponentldInstance*,U32,U32);

void f7995(wasmcomponentldInstance*,U32,U32);

void f7996(wasmcomponentldInstance*,U32,U32);

void f7997(wasmcomponentldInstance*,U32,U32);

void f7998(wasmcomponentldInstance*,U32,U32);

void f7999(wasmcomponentldInstance*,U32,U32,U32);

void f8000(wasmcomponentldInstance*,U32,U32,U32);

void f8001(wasmcomponentldInstance*,U32,U32,U32);

void f8002(wasmcomponentldInstance*,U32,U32,U32);

void f8003(wasmcomponentldInstance*,U32,U32,U32);

void f8004(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8005(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8006(wasmcomponentldInstance*,U32,U32);

void f8007(wasmcomponentldInstance*,U32,U32);

void f8008(wasmcomponentldInstance*,U32,U32);

void f8009(wasmcomponentldInstance*,U32,U32);

void f8010(wasmcomponentldInstance*,U32,U32);

void f8011(wasmcomponentldInstance*,U32,U32);

void f8012(wasmcomponentldInstance*,U32,U32);

void f8013(wasmcomponentldInstance*,U32,U32);

void f8014(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8015(wasmcomponentldInstance*,U32,U32,U32);

void f8016(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8017(wasmcomponentldInstance*,U32,U32,U32);

void f8018(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8019(wasmcomponentldInstance*,U32,U32,U32);

void f8020(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8021(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8022(wasmcomponentldInstance*,U32,U32,U32);

void f8023(wasmcomponentldInstance*,U32,U32,U32);

void f8024(wasmcomponentldInstance*,U32,U32);

void f8025(wasmcomponentldInstance*,U32,U32,U32);

void f8026(wasmcomponentldInstance*,U32,U32,U32);

void f8027(wasmcomponentldInstance*,U32,U32,U32);

void f8028(wasmcomponentldInstance*,U32,U32,U32);

void f8029(wasmcomponentldInstance*,U32,U32,U32);

void f8030(wasmcomponentldInstance*,U32,U32,U32);

void f8031(wasmcomponentldInstance*,U32,U32,U32);

void f8032(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8033(wasmcomponentldInstance*,U32,U32,U32);

void f8034(wasmcomponentldInstance*,U32,U32,U32);

void f8035(wasmcomponentldInstance*,U32,U32,U32);

void f8036(wasmcomponentldInstance*,U32,U32,U32);

void f8037(wasmcomponentldInstance*,U32,U32);

void f8038(wasmcomponentldInstance*,U32,U32,U32);

void f8039(wasmcomponentldInstance*,U32,U32,U32);

void f8040(wasmcomponentldInstance*,U32,U32,U32);

void f8041(wasmcomponentldInstance*,U32,U32,U32);

void f8042(wasmcomponentldInstance*,U32,U32,U32);

void f8043(wasmcomponentldInstance*,U32,U32,U32);

void f8044(wasmcomponentldInstance*,U32,U32,U32);

void f8045(wasmcomponentldInstance*,U32,U32,U32);

void f8046(wasmcomponentldInstance*,U32,U32,U32);

void f8047(wasmcomponentldInstance*,U32,U32,U32);

void f8048(wasmcomponentldInstance*,U32,U32,U32);

void f8049(wasmcomponentldInstance*,U32,U32,U32);

void f8050(wasmcomponentldInstance*,U32,U32,U32);

void f8051(wasmcomponentldInstance*,U32,U32,U32);

void f8052(wasmcomponentldInstance*,U32,U32,U32);

void f8053(wasmcomponentldInstance*,U32,U32,U32);

void f8054(wasmcomponentldInstance*,U32,U32,U32);

void f8055(wasmcomponentldInstance*,U32,U32,U32);

void f8056(wasmcomponentldInstance*,U32,U32,U32);

void f8057(wasmcomponentldInstance*,U32,U32,U32);

void f8058(wasmcomponentldInstance*,U32,U32,U32);

void f8059(wasmcomponentldInstance*,U32,U32,U32);

void f8060(wasmcomponentldInstance*,U32,U32,U32);

void f8061(wasmcomponentldInstance*,U32,U32,U32);

void f8062(wasmcomponentldInstance*,U32,U32,U32);

void f8063(wasmcomponentldInstance*,U32,U32,U32);

void f8064(wasmcomponentldInstance*,U32,U32,U32);

void f8065(wasmcomponentldInstance*,U32,U32,U32);

void f8066(wasmcomponentldInstance*,U32,U32,U32);

void f8067(wasmcomponentldInstance*,U32,U32,U32);

void f8068(wasmcomponentldInstance*,U32,U32,U32);

void f8069(wasmcomponentldInstance*,U32,U32,U32);

void f8070(wasmcomponentldInstance*,U32,U32,U32);

void f8071(wasmcomponentldInstance*,U32,U32,U32);

void f8072(wasmcomponentldInstance*,U32,U32,U32);

void f8073(wasmcomponentldInstance*,U32,U32,U32);

void f8074(wasmcomponentldInstance*,U32,U32,U32);

void f8075(wasmcomponentldInstance*,U32,U32,U32);

void f8076(wasmcomponentldInstance*,U32,U32,U32);

void f8077(wasmcomponentldInstance*,U32,U32,U32);

void f8078(wasmcomponentldInstance*,U32,U32,U32);

void f8079(wasmcomponentldInstance*,U32,U32,U32);

void f8080(wasmcomponentldInstance*,U32,U32,U32);

void f8081(wasmcomponentldInstance*,U32,U32,U32);

void f8082(wasmcomponentldInstance*,U32,U32,U32);

void f8083(wasmcomponentldInstance*,U32,U32,U32);

void f8084(wasmcomponentldInstance*,U32,U32,U32);

void f8085(wasmcomponentldInstance*,U32,U32,U32);

void f8086(wasmcomponentldInstance*,U32,U32,U32);

void f8087(wasmcomponentldInstance*,U32,U32,U32);

void f8088(wasmcomponentldInstance*,U32,U32,U32);

void f8089(wasmcomponentldInstance*,U32,U32,U32);

void f8090(wasmcomponentldInstance*,U32,U32,U32);

void f8091(wasmcomponentldInstance*,U32,U32,U32);

void f8092(wasmcomponentldInstance*,U32,U32,U32);

void f8093(wasmcomponentldInstance*,U32,U32,U32);

void f8094(wasmcomponentldInstance*,U32,U32,U32);

void f8095(wasmcomponentldInstance*,U32,U32,U32);

void f8096(wasmcomponentldInstance*,U32,U32,U32);

void f8097(wasmcomponentldInstance*,U32,U32,U32);

void f8098(wasmcomponentldInstance*,U32,U32,U32);

void f8099(wasmcomponentldInstance*,U32,U32,U32);

void f8100(wasmcomponentldInstance*,U32,U32,U32);

void f8101(wasmcomponentldInstance*,U32,U32,U32);

void f8102(wasmcomponentldInstance*,U32,U32,U32);

void f8103(wasmcomponentldInstance*,U32,U32);

void f8104(wasmcomponentldInstance*,U32,U32,U32);

void f8105(wasmcomponentldInstance*,U32,U32,U32);

void f8106(wasmcomponentldInstance*,U32,U32,U32);

void f8107(wasmcomponentldInstance*,U32,U32,U32);

void f8108(wasmcomponentldInstance*,U32,U32);

void f8109(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8110(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8111(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8112(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8113(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8114(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8115(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8116(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8117(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8118(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8119(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8120(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8121(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8122(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8123(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8124(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8125(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8126(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8127(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8128(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8129(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8130(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8131(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8132(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8133(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8134(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8135(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8136(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8137(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8138(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8139(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8140(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8141(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8142(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8143(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8144(wasmcomponentldInstance*,U32,U32);

void f8145(wasmcomponentldInstance*,U32,U32,U32);

void f8146(wasmcomponentldInstance*,U32,U32,U32);

void f8147(wasmcomponentldInstance*,U32,U32);

void f8148(wasmcomponentldInstance*,U32,U32,U32);

void f8149(wasmcomponentldInstance*,U32,U32,U32);

void f8150(wasmcomponentldInstance*,U32,U32,U32);

void f8151(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8152(wasmcomponentldInstance*,U32,U32,U32);

void f8153(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8154(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8155(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8156(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8157(wasmcomponentldInstance*,U32,U32);

void f8158(wasmcomponentldInstance*,U32,U32);

void f8159(wasmcomponentldInstance*,U32,U32);

void f8160(wasmcomponentldInstance*,U32,U32);

void f8161(wasmcomponentldInstance*,U32,U32,U32);

void f8162(wasmcomponentldInstance*,U32,U32);

void f8163(wasmcomponentldInstance*,U32,U32);

void f8164(wasmcomponentldInstance*,U32);

void f8165(wasmcomponentldInstance*,U32);

void f8166(wasmcomponentldInstance*,U32,U32);

U64 f8167(wasmcomponentldInstance*,U32,U32);

U32 f8168(wasmcomponentldInstance*,U32,U32);

U64 f8169(wasmcomponentldInstance*,U32,U32);

void f8170(wasmcomponentldInstance*,U32,U32,U32);

U64 f8171(wasmcomponentldInstance*,U64,U64,U32);

void f8172(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8173(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8174(wasmcomponentldInstance*,U32,U32,U32);

U64 f8175(wasmcomponentldInstance*,U32,U32);

void f8176(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8177(wasmcomponentldInstance*,U32,U32,U32,U32);

U64 f8178(wasmcomponentldInstance*,U32,U32);

void f8179(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8180(wasmcomponentldInstance*,U32,U32);

void f8181(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8182(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8183(wasmcomponentldInstance*,U32,U32);

void f8184(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8185(wasmcomponentldInstance*,U32,U32);

void f8186(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8187(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8188(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8189(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8190(wasmcomponentldInstance*,U32,U32,U64);

void f8191(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8192(wasmcomponentldInstance*,U32,U32,U32);

void f8193(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8194(wasmcomponentldInstance*,U32,U32,U32);

void f8195(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8196(wasmcomponentldInstance*,U32,U32,U32);

void f8197(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8198(wasmcomponentldInstance*,U32,U32,U32);

void f8199(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8200(wasmcomponentldInstance*,U32,U32,U32);

void f8201(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8202(wasmcomponentldInstance*,U32,U32,U32);

void f8203(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8204(wasmcomponentldInstance*,U32,U32,U32);

void f8205(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8206(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8207(wasmcomponentldInstance*,U32,U32,U32);

void f8208(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8209(wasmcomponentldInstance*,U32,U32,U32);

void f8210(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8211(wasmcomponentldInstance*,U32,U32,U32);

void f8212(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8213(wasmcomponentldInstance*,U32,U32,U32);

void f8214(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8215(wasmcomponentldInstance*,U32,U32,U32);

void f8216(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8217(wasmcomponentldInstance*,U32,U32,U32);

void f8218(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8219(wasmcomponentldInstance*,U32,U32,U32);

void f8220(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U64 f8221(wasmcomponentldInstance*,U32,U32,U32);

U32 f8222(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8223(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8224(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f8225(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f8226(wasmcomponentldInstance*,U32,U64,U32,U32);

U32 f8227(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

U32 f8228(wasmcomponentldInstance*,U32,U64,U32,U32,U32);

void f8229(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8230(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8231(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8232(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8233(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8234(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8235(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8236(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8237(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8238(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8239(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8240(wasmcomponentldInstance*,U32,U32,U64,U32,U32,U32);

void f8241(wasmcomponentldInstance*,U32,U32);

void f8242(wasmcomponentldInstance*,U32,U32);

U32 f8243(wasmcomponentldInstance*,U32,U32);

U32 f8244(wasmcomponentldInstance*,U32,U32);

U32 f8245(wasmcomponentldInstance*,U32,U32);

U32 f8246(wasmcomponentldInstance*,U32,U32);

U32 f8247(wasmcomponentldInstance*,U32,U32);

U32 f8248(wasmcomponentldInstance*,U32,U32);

void f8249(wasmcomponentldInstance*,U32);

U32 f8250(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8251(wasmcomponentldInstance*,U32,U32);

U32 f8252(wasmcomponentldInstance*,U32,U32);

U32 f8253(wasmcomponentldInstance*,U32,U32,U32);

void f8254(wasmcomponentldInstance*,U32,U32,U32);

void f8255(wasmcomponentldInstance*,U32,U32);

U32 f8256(wasmcomponentldInstance*,U32,U32);

U32 f8257(wasmcomponentldInstance*,U32,U32);

void f8258(wasmcomponentldInstance*,U32,U32,U32);

U32 f8259(wasmcomponentldInstance*,U32,U32,U32);

U32 f8260(wasmcomponentldInstance*,U32,U32);

void f8261(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8262(wasmcomponentldInstance*,U32,U32,U32,U32,U64);

void f8263(wasmcomponentldInstance*,U32,U32,U32);

U32 f8264(wasmcomponentldInstance*,U32,U32);

U32 f8265(wasmcomponentldInstance*,U32,U32,U32);

U32 f8266(wasmcomponentldInstance*,U32);

U32 f8267(wasmcomponentldInstance*,U32,U32);

void f8268(wasmcomponentldInstance*,U32,U32);

void f8269(wasmcomponentldInstance*,U32,U32);

void f8270(wasmcomponentldInstance*,U32,U32);

void f8271(wasmcomponentldInstance*,U32,U32);

U32 f8272(wasmcomponentldInstance*,U32,U32);

U32 f8273(wasmcomponentldInstance*,U32,U32);

void f8274(wasmcomponentldInstance*,U32,U32);

void f8275(wasmcomponentldInstance*,U32,U32);

void f8276(wasmcomponentldInstance*,U32,U32);

void f8277(wasmcomponentldInstance*,U32,U32);

void f8278(wasmcomponentldInstance*,U32,U32);

void f8279(wasmcomponentldInstance*,U32,U32);

void f8280(wasmcomponentldInstance*,U32,U32);

void f8281(wasmcomponentldInstance*,U32,U32);

void f8282(wasmcomponentldInstance*,U32,U32);

void f8283(wasmcomponentldInstance*,U32,U32);

void f8284(wasmcomponentldInstance*,U32,U32);

void f8285(wasmcomponentldInstance*,U32,U32,U32);

void f8286(wasmcomponentldInstance*,U32,U32);

void f8287(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8288(wasmcomponentldInstance*,U32,U32);

void f8289(wasmcomponentldInstance*,U32,U32);

void f8290(wasmcomponentldInstance*,U32,U32,U32);

void f8291(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8292(wasmcomponentldInstance*,U32,U32,U32);

void f8293(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8294(wasmcomponentldInstance*,U32,U32);

void f8295(wasmcomponentldInstance*,U32,U32);

void f8296(wasmcomponentldInstance*,U32,U32);

void f8297(wasmcomponentldInstance*,U32,U32);

void f8298(wasmcomponentldInstance*,U32,U32);

void f8299(wasmcomponentldInstance*,U32,U32);

void f8300(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8301(wasmcomponentldInstance*,U32,U32,U32);

void f8302(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8303(wasmcomponentldInstance*,U32,U32,U32);

void f8304(wasmcomponentldInstance*,U32,U32,U32);

void f8305(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8306(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8307(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8308(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8309(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8310(wasmcomponentldInstance*,U32,U32);

void f8311(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8312(wasmcomponentldInstance*,U32,U32,U32);

void f8313(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8314(wasmcomponentldInstance*,U32,U32,U32);

U32 f8315(wasmcomponentldInstance*,U32,U32);

U32 f8316(wasmcomponentldInstance*,U32,U32,U32);

U32 f8317(wasmcomponentldInstance*,U32,U32);

U32 f8318(wasmcomponentldInstance*,U32,U32,U32);

U32 f8319(wasmcomponentldInstance*,U32,U32);

U32 f8320(wasmcomponentldInstance*,U32,U32,U32);

U32 f8321(wasmcomponentldInstance*,U32,U32);

U32 f8322(wasmcomponentldInstance*,U32,U32);

void f8323(wasmcomponentldInstance*,U32,U32,U32);

void f8324(wasmcomponentldInstance*,U32,U32,U32);

void f8325(wasmcomponentldInstance*,U32,U32,U32);

void f8326(wasmcomponentldInstance*,U32,U32,U32);

U32 f8327(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8328(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8329(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8330(wasmcomponentldInstance*,U32,U32);

void f8331(wasmcomponentldInstance*,U32,U32);

void f8332(wasmcomponentldInstance*,U32,U32);

void f8333(wasmcomponentldInstance*,U32,U32);

void f8334(wasmcomponentldInstance*,U32,U32);

void f8335(wasmcomponentldInstance*,U32,U32);

U32 f8336(wasmcomponentldInstance*,U32,U32,U32);

void f8337(wasmcomponentldInstance*,U32,U32);

void f8338(wasmcomponentldInstance*,U32,U32);

void f8339(wasmcomponentldInstance*,U32,U32);

void f8340(wasmcomponentldInstance*,U32,U32);

void f8341(wasmcomponentldInstance*,U32,U32);

void f8342(wasmcomponentldInstance*,U32,U32);

U32 f8343(wasmcomponentldInstance*,U32,U32);

U32 f8344(wasmcomponentldInstance*,U32,U32);

void f8345(wasmcomponentldInstance*,U32,U32);

void f8346(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8347(wasmcomponentldInstance*,U32,U32);

U32 f8348(wasmcomponentldInstance*,U32,U32);

U32 f8349(wasmcomponentldInstance*,U32,U32);

U32 f8350(wasmcomponentldInstance*,U32,U32);

U32 f8351(wasmcomponentldInstance*,U32,U32);

U32 f8352(wasmcomponentldInstance*,U32,U32);

U32 f8353(wasmcomponentldInstance*,U32,U32);

U32 f8354(wasmcomponentldInstance*,U32,U32);

U32 f8355(wasmcomponentldInstance*,U32,U32);

U32 f8356(wasmcomponentldInstance*,U32,U32,U32);

U32 f8357(wasmcomponentldInstance*,U32,U32);

void f8358(wasmcomponentldInstance*);

U32 f8359(wasmcomponentldInstance*,U32,U32,U32);

U32 f8360(wasmcomponentldInstance*,U32,U32);

void f8361(wasmcomponentldInstance*,U32,U32,U32);

U32 f8362(wasmcomponentldInstance*,U32,U32);

U32 f8363(wasmcomponentldInstance*,U32,U32);

U32 f8364(wasmcomponentldInstance*,U32,U32,U32);

U32 f8365(wasmcomponentldInstance*,U32);

U32 f8366(wasmcomponentldInstance*,U32,U32,U32);

U32 f8367(wasmcomponentldInstance*,U32,U32);

U32 f8368(wasmcomponentldInstance*,U32,U32);

void f8369(wasmcomponentldInstance*,U32,U32,U32);

void f8370(wasmcomponentldInstance*,U32,U32);

void f8371(wasmcomponentldInstance*,U32,U32);

void f8372(wasmcomponentldInstance*,U32);

U32 f8373(wasmcomponentldInstance*,U32,U32);

U32 f8374(wasmcomponentldInstance*,U32,U32);

void f8375(wasmcomponentldInstance*,U32);

void f8376(wasmcomponentldInstance*,U32,U32);

void f8377(wasmcomponentldInstance*,U32,U32);

U32 f8378(wasmcomponentldInstance*,U32,U32);

U32 f8379(wasmcomponentldInstance*,U32,U32);

U32 f8380(wasmcomponentldInstance*,U32,U32);

U32 f8381(wasmcomponentldInstance*,U32,U32);

U32 f8382(wasmcomponentldInstance*,U32,U32);

U32 f8383(wasmcomponentldInstance*,U32,U32);

U32 f8384(wasmcomponentldInstance*,U32,U32);

U32 f8385(wasmcomponentldInstance*,U32,U32);

U32 f8386(wasmcomponentldInstance*,U32,U32);

void f8387(wasmcomponentldInstance*,U32,U32,U32);

void f8388(wasmcomponentldInstance*,U32,U32,U32);

U32 f8389(wasmcomponentldInstance*,U32);

U32 f8390(wasmcomponentldInstance*,U32,U32);

U32 f8391(wasmcomponentldInstance*,U32,U32);

void f8392(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8393(wasmcomponentldInstance*,U32,U32,U32);

void f8394(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8395(wasmcomponentldInstance*,U32,U32,U32);

U32 f8396(wasmcomponentldInstance*,U32,U32);

U32 f8397(wasmcomponentldInstance*,U32,U32);

void f8398(wasmcomponentldInstance*,U32);

void f8399(wasmcomponentldInstance*,U32);

void f8400(wasmcomponentldInstance*,U32);

void f8401(wasmcomponentldInstance*,U32,U32);

U32 f8402(wasmcomponentldInstance*,U32,U32);

U32 f8403(wasmcomponentldInstance*,U32,U32);

void f8404(wasmcomponentldInstance*,U32,U32,U32);

void f8405(wasmcomponentldInstance*,U32,U32);

void f8406(wasmcomponentldInstance*,U32,U32);

void f8407(wasmcomponentldInstance*,U32,U32);

void f8408(wasmcomponentldInstance*,U32,U32);

void f8409(wasmcomponentldInstance*,U32,U32);

void f8410(wasmcomponentldInstance*,U32,U32,U32);

void f8411(wasmcomponentldInstance*,U32,U32);

void f8412(wasmcomponentldInstance*,U32,U32);

U32 f8413(wasmcomponentldInstance*,U32,U32);

U32 f8414(wasmcomponentldInstance*,U32,U32);

U32 f8415(wasmcomponentldInstance*,U32,U32);

U32 f8416(wasmcomponentldInstance*,U32,U32);

U32 f8417(wasmcomponentldInstance*,U32,U32);

U32 f8418(wasmcomponentldInstance*,U32,U32);

U32 f8419(wasmcomponentldInstance*,U32,U32);

U32 f8420(wasmcomponentldInstance*,U32,U32);

U32 f8421(wasmcomponentldInstance*,U32,U32);

U32 f8422(wasmcomponentldInstance*,U32,U32);

U32 f8423(wasmcomponentldInstance*,U32,U32);

U32 f8424(wasmcomponentldInstance*,U32,U32);

void f8425(wasmcomponentldInstance*,U32,U32);

void f8426(wasmcomponentldInstance*,U32);

void f8427(wasmcomponentldInstance*,U32);

void f8428(wasmcomponentldInstance*,U32);

void f8429(wasmcomponentldInstance*,U32);

void f8430(wasmcomponentldInstance*,U32);

U32 f8431(wasmcomponentldInstance*,U32,U32);

U32 f8432(wasmcomponentldInstance*,U32,U32);

U32 f8433(wasmcomponentldInstance*,U32,U32,U32);

U32 f8434(wasmcomponentldInstance*,U32,U32);

void f8435(wasmcomponentldInstance*,U32,U32,U32);

U32 f8436(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8437(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8438(wasmcomponentldInstance*,U32,U32,U32);

void f8439(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32);

void f8440(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f8441(wasmcomponentldInstance*,U32,U32);

void f8442(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8443(wasmcomponentldInstance*,U32,U32);

U32 f8444(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8445(wasmcomponentldInstance*,U32,U32,U32);

void f8446(wasmcomponentldInstance*,U32,U32,U32);

void f8447(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8448(wasmcomponentldInstance*,U32,U32,U32);

void f8449(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8450(wasmcomponentldInstance*,U32,U32,U32);

void f8451(wasmcomponentldInstance*,U32,U32,U32);

void f8452(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8453(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8454(wasmcomponentldInstance*,U32,U32,U32);

void f8455(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8456(wasmcomponentldInstance*,U32,U32,U32);

void f8457(wasmcomponentldInstance*,U32,U32,U32);

void f8458(wasmcomponentldInstance*,U32,U32,U32);

void f8459(wasmcomponentldInstance*,U32,U32,U32);

void f8460(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8461(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8462(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8463(wasmcomponentldInstance*,U32,U32,U32);

void f8464(wasmcomponentldInstance*,U32,U32);

void f8465(wasmcomponentldInstance*,U32,U32,U32);

void f8466(wasmcomponentldInstance*,U32,U32,U32);

void f8467(wasmcomponentldInstance*,U32,U32,U32);

void f8468(wasmcomponentldInstance*,U32,U32,U32);

void f8469(wasmcomponentldInstance*,U32);

U32 f8470(wasmcomponentldInstance*,U32,U32);

U32 f8471(wasmcomponentldInstance*,U32,U32);

U32 f8472(wasmcomponentldInstance*,U32,U32,U32);

void f8473(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8474(wasmcomponentldInstance*,U32,U32,U32);

void f8475(wasmcomponentldInstance*,U32,U32,U32);

void f8476(wasmcomponentldInstance*,U32,U32,U32);

U32 f8477(wasmcomponentldInstance*,U32,U32);

void f8478(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8479(wasmcomponentldInstance*,U32,U32,U32);

void f8480(wasmcomponentldInstance*,U32,U32,U32);

void f8481(wasmcomponentldInstance*,U32,U32,U32);

void f8482(wasmcomponentldInstance*,U32,U32,U32);

void f8483(wasmcomponentldInstance*,U32,U32);

void f8484(wasmcomponentldInstance*,U32,U32,U32);

void f8485(wasmcomponentldInstance*,U32);

void f8486(wasmcomponentldInstance*,U32);

void f8487(wasmcomponentldInstance*,U32);

void f8488(wasmcomponentldInstance*,U32);

void f8489(wasmcomponentldInstance*,U32);

void f8490(wasmcomponentldInstance*,U32);

void f8491(wasmcomponentldInstance*,U32);

void f8492(wasmcomponentldInstance*,U32);

void f8493(wasmcomponentldInstance*,U32);

void f8494(wasmcomponentldInstance*,U32);

U32 f8495(wasmcomponentldInstance*,U32,U32);

U32 f8496(wasmcomponentldInstance*,U32,U32);

void f8497(wasmcomponentldInstance*,U32,U32);

void f8498(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8499(wasmcomponentldInstance*,U32);

void f8500(wasmcomponentldInstance*,U32);

void f8501(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8502(wasmcomponentldInstance*,U32,U32);

void f8503(wasmcomponentldInstance*,U32,U32,U32);

void f8504(wasmcomponentldInstance*,U32,U32);

void f8505(wasmcomponentldInstance*,U32,U32);

U32 f8506(wasmcomponentldInstance*,U32,U32,U32);

void f8507(wasmcomponentldInstance*,U32,U32,U32);

U32 f8508(wasmcomponentldInstance*,U32,U32);

void f8509(wasmcomponentldInstance*,U32,U32);

void f8510(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8511(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8512(wasmcomponentldInstance*,U32,U32,U32);

void f8513(wasmcomponentldInstance*,U32,U32,U32);

void f8514(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8515(wasmcomponentldInstance*,U32,U32,U32);

U32 f8516(wasmcomponentldInstance*,U32,U32,U32);

U32 f8517(wasmcomponentldInstance*,U32,U32);

U32 f8518(wasmcomponentldInstance*,U32,U32);

U32 f8519(wasmcomponentldInstance*,U32,U32);

void f8520(wasmcomponentldInstance*,U32);

void f8521(wasmcomponentldInstance*,U32);

void f8522(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8523(wasmcomponentldInstance*,U32,U32);

U32 f8524(wasmcomponentldInstance*,U32,U32);

U32 f8525(wasmcomponentldInstance*,U32,U32,U32);

U32 f8526(wasmcomponentldInstance*,U32,U32);

U32 f8527(wasmcomponentldInstance*,U32);

U32 f8528(wasmcomponentldInstance*,U32,U32);

U32 f8529(wasmcomponentldInstance*,U32,U32);

U32 f8530(wasmcomponentldInstance*,U32,U32,U32);

U32 f8531(wasmcomponentldInstance*,U32,U32,U32);

U32 f8532(wasmcomponentldInstance*,U32,U32);

U32 f8533(wasmcomponentldInstance*,U32,U32);

U32 f8534(wasmcomponentldInstance*,U32,U32);

U32 f8535(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8536(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8537(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8538(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f8539(wasmcomponentldInstance*,U32,U32,U32);

U32 f8540(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8541(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8542(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8543(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8544(wasmcomponentldInstance*,U32,U32,U32);

void f8545(wasmcomponentldInstance*,U32,U32,U32);

void f8546(wasmcomponentldInstance*,U32,U32);

void f8547(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8548(wasmcomponentldInstance*,U32,U32);

void f8549(wasmcomponentldInstance*,U32,U32);

U32 f8550(wasmcomponentldInstance*,U32,U32,U32);

void f8551(wasmcomponentldInstance*,U32,U32,U32);

void f8552(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8553(wasmcomponentldInstance*,U32,U32);

void f8554(wasmcomponentldInstance*,U32,U32,U32);

void f8555(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8556(wasmcomponentldInstance*,U32,U32);

U32 f8557(wasmcomponentldInstance*,U32,U32);

U32 f8558(wasmcomponentldInstance*,U32,U32);

void f8559(wasmcomponentldInstance*,U32,U32,U32);

U32 f8560(wasmcomponentldInstance*,U32,U32);

void f8561(wasmcomponentldInstance*,U32,U32,U32);

U32 f8562(wasmcomponentldInstance*,U32,U32);

void f8563(wasmcomponentldInstance*,U32);

void f8564(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f8565(wasmcomponentldInstance*,U32,U32);

void f8566(wasmcomponentldInstance*,U32,U32,U32);

void f8567(wasmcomponentldInstance*,U32);

void f8568(wasmcomponentldInstance*,U32);

void f8569(wasmcomponentldInstance*,U32);

void f8570(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8571(wasmcomponentldInstance*,U32);

U32 f8572(wasmcomponentldInstance*,U32,U32);

void f8573(wasmcomponentldInstance*,U32,U32);

void f8574(wasmcomponentldInstance*,U32,U32,U32);

U32 f8575(wasmcomponentldInstance*,U32,U32,U32);

U32 f8576(wasmcomponentldInstance*,U32,U32);

U32 f8577(wasmcomponentldInstance*,U32,U32);

void f8578(wasmcomponentldInstance*,U32,U32);

void f8579(wasmcomponentldInstance*,U32,U32,U32);

U32 f8580(wasmcomponentldInstance*,U32);

void f8581(wasmcomponentldInstance*,U32,U32,U64,U64);

void f8582(wasmcomponentldInstance*,U32,U32,U32);

void f8583(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8584(wasmcomponentldInstance*,U32);

U32 f8585(wasmcomponentldInstance*,U32,U32);

U32 f8586(wasmcomponentldInstance*,U32,U32);

U32 f8587(wasmcomponentldInstance*,U32,U32,U32);

U32 f8588(wasmcomponentldInstance*,U32,U32);

void f8589(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8590(wasmcomponentldInstance*,U32,U32,U32);

U32 f8591(wasmcomponentldInstance*,U32,U32);

U32 f8592(wasmcomponentldInstance*,U32,U32);

void f8593(wasmcomponentldInstance*,U32);

void f8594(wasmcomponentldInstance*,U32,U32);

U32 f8595(wasmcomponentldInstance*,U32,U32);

void f8596(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8597(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8598(wasmcomponentldInstance*,U32,U32);

void f8599(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8600(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8601(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8602(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32);

void f8603(wasmcomponentldInstance*,U32,U32,U32);

void f8604(wasmcomponentldInstance*,U32,U32,U32);

void f8605(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8606(wasmcomponentldInstance*,U32,U32,U32);

U32 f8607(wasmcomponentldInstance*,U32,U32,U32);

U32 f8608(wasmcomponentldInstance*,U32,U32);

void f8609(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8610(wasmcomponentldInstance*,U32,U32);

void f8611(wasmcomponentldInstance*,U32,U32);

void f8612(wasmcomponentldInstance*,U32,U32,U32);

void f8613(wasmcomponentldInstance*,U32,U32,U32);

void f8614(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8615(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8616(wasmcomponentldInstance*,U32);

U32 f8617(wasmcomponentldInstance*,U32);

void f8618(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8619(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8620(wasmcomponentldInstance*,U32,U32);

void f8621(wasmcomponentldInstance*,U32,U32);

void f8622(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8623(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8624(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8625(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8626(wasmcomponentldInstance*,U32,U32,U32);

void f8627(wasmcomponentldInstance*,U32,U32,U32);

U32 f8628(wasmcomponentldInstance*,U32,U32);

U32 f8629(wasmcomponentldInstance*,U32,U32);

U32 f8630(wasmcomponentldInstance*,U32,U32);

U32 f8631(wasmcomponentldInstance*,U32,U32);

U32 f8632(wasmcomponentldInstance*,U32,U32);

U32 f8633(wasmcomponentldInstance*,U32,U32);

void f8634(wasmcomponentldInstance*,U32);

void f8635(wasmcomponentldInstance*,U32);

void f8636(wasmcomponentldInstance*,U32);

U32 f8637(wasmcomponentldInstance*,U32,U32);

U32 f8638(wasmcomponentldInstance*,U32,U32);

U32 f8639(wasmcomponentldInstance*,U32,U32,U32);

U32 f8640(wasmcomponentldInstance*,U32);

U32 f8641(wasmcomponentldInstance*,U32);

U32 f8642(wasmcomponentldInstance*,U32);

U32 f8643(wasmcomponentldInstance*,U32);

U32 f8644(wasmcomponentldInstance*,U32,U32,U32);

U32 f8645(wasmcomponentldInstance*,U32,U32,U32);

void f8646(wasmcomponentldInstance*,U32,U32,U32);

void f8647(wasmcomponentldInstance*,U32,U32,U32);

U32 f8648(wasmcomponentldInstance*,U32,U32);

U32 f8649(wasmcomponentldInstance*,U32,U32,U32);

void f8650(wasmcomponentldInstance*,U32,U32,U32);

void f8651(wasmcomponentldInstance*,U32,U32);

void f8652(wasmcomponentldInstance*,U32,U32);

void f8653(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8654(wasmcomponentldInstance*,U32,U32);

void f8655(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8656(wasmcomponentldInstance*,U32,U32);

void f8657(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8658(wasmcomponentldInstance*,U32);

U32 f8659(wasmcomponentldInstance*,U32,U32);

void f8660(wasmcomponentldInstance*,U32);

void f8661(wasmcomponentldInstance*,U32,U32,U32);

void f8662(wasmcomponentldInstance*,U32,U32,U32);

U32 f8663(wasmcomponentldInstance*,U32,U32);

U32 f8664(wasmcomponentldInstance*,U32,U32);

U32 f8665(wasmcomponentldInstance*,U32,U32);

void f8666(wasmcomponentldInstance*,U32,U32);

U32 f8667(wasmcomponentldInstance*,U32,U32,U32);

U32 f8668(wasmcomponentldInstance*,U32,U32);

void f8669(wasmcomponentldInstance*,U32,U32);

void f8670(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8671(wasmcomponentldInstance*,U32,U32);

void f8672(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8673(wasmcomponentldInstance*,U32,U32);

void f8674(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8675(wasmcomponentldInstance*,U32,U32);

void f8676(wasmcomponentldInstance*,U32,U32);

void f8677(wasmcomponentldInstance*,U32,U32);

U32 f8678(wasmcomponentldInstance*,U32,U32);

U32 f8679(wasmcomponentldInstance*,U32,U32);

U32 f8680(wasmcomponentldInstance*,U32,U32);

void f8681(wasmcomponentldInstance*,U32);

void f8682(wasmcomponentldInstance*,U32);

U32 f8683(wasmcomponentldInstance*,U32,U32,U32);

U32 f8684(wasmcomponentldInstance*,U32,U32,U32);

void f8685(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8686(wasmcomponentldInstance*,U32,U32);

void f8687(wasmcomponentldInstance*,U32,U32);

void f8688(wasmcomponentldInstance*,U32,U32);

void f8689(wasmcomponentldInstance*,U32,U32);

void f8690(wasmcomponentldInstance*,U32,U32);

void f8691(wasmcomponentldInstance*,U32,U32);

void f8692(wasmcomponentldInstance*,U32,U32);

void f8693(wasmcomponentldInstance*,U32,U32);

void f8694(wasmcomponentldInstance*,U32,U32);

void f8695(wasmcomponentldInstance*,U32,U32);

void f8696(wasmcomponentldInstance*,U32,U32);

void f8697(wasmcomponentldInstance*,U32,U32);

void f8698(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8699(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8700(wasmcomponentldInstance*,U32,U32);

U32 f8701(wasmcomponentldInstance*,U32,U32);

U32 f8702(wasmcomponentldInstance*,U32,U32);

void f8703(wasmcomponentldInstance*,U32);

void f8704(wasmcomponentldInstance*,U32);

void f8705(wasmcomponentldInstance*,U32);

void f8706(wasmcomponentldInstance*,U32);

void f8707(wasmcomponentldInstance*,U32,U32);

void f8708(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8709(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8710(wasmcomponentldInstance*,U32,U32);

void f8711(wasmcomponentldInstance*,U32,U32,U32);

U32 f8712(wasmcomponentldInstance*,U32,U32,U32);

U32 f8713(wasmcomponentldInstance*,U32,U32);

void f8714(wasmcomponentldInstance*,U32,U32);

void f8715(wasmcomponentldInstance*,U32,U32);

U32 f8716(wasmcomponentldInstance*,U32,U32);

U32 f8717(wasmcomponentldInstance*,U32,U32);

void f8718(wasmcomponentldInstance*,U32);

void f8719(wasmcomponentldInstance*,U32,U32,U32);

U32 f8720(wasmcomponentldInstance*,U32,U32,U32);

U32 f8721(wasmcomponentldInstance*,U32,U32);

void f8722(wasmcomponentldInstance*,U32,U32);

void f8723(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8724(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8725(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8726(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8727(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8728(wasmcomponentldInstance*,U32,U32);

void f8729(wasmcomponentldInstance*,U32,U32);

void f8730(wasmcomponentldInstance*,U32,U32,U32);

void f8731(wasmcomponentldInstance*,U32,U32,U32);

U32 f8732(wasmcomponentldInstance*,U32,U32);

U32 f8733(wasmcomponentldInstance*,U32,U32);

void f8734(wasmcomponentldInstance*,U32,U32,U32);

void f8735(wasmcomponentldInstance*,U32);

U32 f8736(wasmcomponentldInstance*,U32,U32);

void f8737(wasmcomponentldInstance*,U32,U32,U32);

void f8738(wasmcomponentldInstance*,U32,U32);

void f8739(wasmcomponentldInstance*,U32,U32);

void f8740(wasmcomponentldInstance*,U32,U32,U32);

void f8741(wasmcomponentldInstance*,U32,U32,U32);

void f8742(wasmcomponentldInstance*,U32,U32,U32);

void f8743(wasmcomponentldInstance*,U32,U32);

void f8744(wasmcomponentldInstance*,U32,U32);

void f8745(wasmcomponentldInstance*,U32,U32);

void f8746(wasmcomponentldInstance*,U32,U64);

U32 f8747(wasmcomponentldInstance*,U32,U32);

U32 f8748(wasmcomponentldInstance*,U32,U32);

U32 f8749(wasmcomponentldInstance*,U32,U32,U32);

U32 f8750(wasmcomponentldInstance*,U32,U32);

U32 f8751(wasmcomponentldInstance*,U32,U32);

void f8752(wasmcomponentldInstance*,U32,U32);

U32 f8753(wasmcomponentldInstance*,U32,U32);

void f8754(wasmcomponentldInstance*,U32,U32);

void f8755(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8756(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8757(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8758(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8759(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8760(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8761(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8762(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8763(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8764(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f8765(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f8766(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f8767(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f8768(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f8769(wasmcomponentldInstance*,U32,U32);

void f8770(wasmcomponentldInstance*,U32,U32);

void f8771(wasmcomponentldInstance*,U32,U32);

void f8772(wasmcomponentldInstance*,U32,U32);

void f8773(wasmcomponentldInstance*,U32,U32);

void f8774(wasmcomponentldInstance*,U32,U32);

void f8775(wasmcomponentldInstance*,U32,U32);

void f8776(wasmcomponentldInstance*,U32,U32);

void f8777(wasmcomponentldInstance*,U32,U32);

void f8778(wasmcomponentldInstance*,U32,U32);

void f8779(wasmcomponentldInstance*,U32,U32);

void f8780(wasmcomponentldInstance*,U32,U32);

void f8781(wasmcomponentldInstance*,U32,U32);

void f8782(wasmcomponentldInstance*,U32);

void f8783(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f8784(wasmcomponentldInstance*,U32,U32);

U32 f8785(wasmcomponentldInstance*,U32,U32);

U32 f8786(wasmcomponentldInstance*,U32,U32,U32);

void f8787(wasmcomponentldInstance*,U32,U32,U32);

U32 f8788(wasmcomponentldInstance*,U32,U32);

U32 f8789(wasmcomponentldInstance*,U32,U32);

void f8790(wasmcomponentldInstance*,U32,U32);

void f8791(wasmcomponentldInstance*,U32,U32);

void f8792(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8793(wasmcomponentldInstance*,U32);

void f8794(wasmcomponentldInstance*,U32,U32,U32);

void f8795(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8796(wasmcomponentldInstance*,U32,U32);

void f8797(wasmcomponentldInstance*,U32,U32);

void f8798(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8799(wasmcomponentldInstance*,U32);

void f8800(wasmcomponentldInstance*,U32,U32,U32);

void f8801(wasmcomponentldInstance*,U32,U32);

void f8802(wasmcomponentldInstance*,U32);

void f8803(wasmcomponentldInstance*,U32);

void f8804(wasmcomponentldInstance*,U32,U32,U32);

void f8805(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8806(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f8807(wasmcomponentldInstance*,U32,U32,U32);

void f8808(wasmcomponentldInstance*,U32,U32);

void f8809(wasmcomponentldInstance*,U32,U32);

void f8810(wasmcomponentldInstance*,U32,U32);

U32 f8811(wasmcomponentldInstance*,U32,U32,U32);

void f8812(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8813(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8814(wasmcomponentldInstance*,U32,U32,U64,U64,U32);

void f8815(wasmcomponentldInstance*,U32,U32);

void f8816(wasmcomponentldInstance*,U32,U32);

void f8817(wasmcomponentldInstance*,U32,U32);

void f8818(wasmcomponentldInstance*,U32,U32,U32);

U32 f8819(wasmcomponentldInstance*,U32,U32);

F64 f8820(wasmcomponentldInstance*,U32,U32,U32,U32);

F64 f8821(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8822(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8823(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8824(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8825(wasmcomponentldInstance*,U32);

void f8826(wasmcomponentldInstance*,U32,U32);

void f8827(wasmcomponentldInstance*,U32,U32,U32);

void f8828(wasmcomponentldInstance*,U32,U32);

U32 f8829(wasmcomponentldInstance*,U32,U32);

U32 f8830(wasmcomponentldInstance*,U32,U32);

U32 f8831(wasmcomponentldInstance*);

U32 f8832(wasmcomponentldInstance*,U32,U32);

U32 f8833(wasmcomponentldInstance*,U32,U32);

U32 f8834(wasmcomponentldInstance*,U32,U32);

U32 f8835(wasmcomponentldInstance*,U32,U32);

void f8836(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8837(wasmcomponentldInstance*,U32,U32);

U32 f8838(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8839(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8840(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8841(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8842(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8843(wasmcomponentldInstance*,U32,U32);

void f8844(wasmcomponentldInstance*,U32,U32,U32);

void f8845(wasmcomponentldInstance*,U32,U32,U32);

void f8846(wasmcomponentldInstance*,U32,U32,U32);

void f8847(wasmcomponentldInstance*,U32,U32,U32);

void f8848(wasmcomponentldInstance*,U32,U32,U64,U64);

U32 f8849(wasmcomponentldInstance*,U32);

U32 f8850(wasmcomponentldInstance*,U32);

void f8851(wasmcomponentldInstance*,U32,U32);

U32 f8852(wasmcomponentldInstance*,U32);

void f8853(wasmcomponentldInstance*,U32,U32);

U32 f8854(wasmcomponentldInstance*,U32);

void f8855(wasmcomponentldInstance*,U32,U32);

void f8856(wasmcomponentldInstance*,U32,U32);

void f8857(wasmcomponentldInstance*,U32,U32,U32);

U32 f8858(wasmcomponentldInstance*,U32);

U32 f8859(wasmcomponentldInstance*,U32);

void f8860(wasmcomponentldInstance*,U32,U32);

void f8861(wasmcomponentldInstance*,U32,U32);

void f8862(wasmcomponentldInstance*,U32,U32);

U32 f8863(wasmcomponentldInstance*,U32,U32);

void f8864(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8865(wasmcomponentldInstance*,U32,U32,U32);

U32 f8866(wasmcomponentldInstance*,U32,U32);

U32 f8867(wasmcomponentldInstance*,U32,U32);

U32 f8868(wasmcomponentldInstance*,U32,U32);

U32 f8869(wasmcomponentldInstance*,U32,U32);

U32 f8870(wasmcomponentldInstance*,U32,U32);

U32 f8871(wasmcomponentldInstance*,U32,U32,U32);

U32 f8872(wasmcomponentldInstance*,U32,U32);

U32 f8873(wasmcomponentldInstance*,U32,U32,U32);

void f8874(wasmcomponentldInstance*,U32,U32);

U32 f8875(wasmcomponentldInstance*,U32,U32);

void f8876(wasmcomponentldInstance*,U32);

void f8877(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8878(wasmcomponentldInstance*,U32,U32);

void f8879(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8880(wasmcomponentldInstance*,U32,U32,U32);

void f8881(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

void f8882(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8883(wasmcomponentldInstance*,U32,U32,U32);

void f8884(wasmcomponentldInstance*,U32);

U32 f8885(wasmcomponentldInstance*,U32,U32);

U32 f8886(wasmcomponentldInstance*,U32,U32);

U32 f8887(wasmcomponentldInstance*,U32,U32,U32);

void f8888(wasmcomponentldInstance*,U32,U32);

U32 f8889(wasmcomponentldInstance*,U32,U32);

U32 f8890(wasmcomponentldInstance*,U32,U32);

void f8891(wasmcomponentldInstance*,U32,U32);

U32 f8892(wasmcomponentldInstance*,U32);

U32 f8893(wasmcomponentldInstance*,U32,U32);

U32 f8894(wasmcomponentldInstance*,U32,U32);

void f8895(wasmcomponentldInstance*,U32,U32,U32);

void f8896(wasmcomponentldInstance*,U32,U32);

void f8897(wasmcomponentldInstance*,U32,U32);

U32 f8898(wasmcomponentldInstance*,U32);

void f8899(wasmcomponentldInstance*,U32,U32);

U32 f8900(wasmcomponentldInstance*,U32,U32);

U32 f8901(wasmcomponentldInstance*,U32,U32);

void f8902(wasmcomponentldInstance*,U32);

void f8903(wasmcomponentldInstance*,U32,U32);

void f8904(wasmcomponentldInstance*,U32,U32);

U32 f8905(wasmcomponentldInstance*,U32,U32);

U32 f8906(wasmcomponentldInstance*,U32,U32);

U32 f8907(wasmcomponentldInstance*,U32,U32);

U32 f8908(wasmcomponentldInstance*,U32,U32);

U32 f8909(wasmcomponentldInstance*,U32,U32);

U32 f8910(wasmcomponentldInstance*,U32,U32);

U32 f8911(wasmcomponentldInstance*,U32,U32);

U32 f8912(wasmcomponentldInstance*,U32,U32);

U32 f8913(wasmcomponentldInstance*,U32,U32);

U32 f8914(wasmcomponentldInstance*,U32,U32);

U32 f8915(wasmcomponentldInstance*,U32,U32);

U32 f8916(wasmcomponentldInstance*,U32,U32);

U32 f8917(wasmcomponentldInstance*,U32,U32);

U32 f8918(wasmcomponentldInstance*,U32,U32);

U32 f8919(wasmcomponentldInstance*,U32,U32);

U32 f8920(wasmcomponentldInstance*,U32,U32);

U32 f8921(wasmcomponentldInstance*,U32,U32);

void f8922(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8923(wasmcomponentldInstance*,U32,U32);

U32 f8924(wasmcomponentldInstance*,U32,U32,U32);

U32 f8925(wasmcomponentldInstance*,U32,U32);

void f8926(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8927(wasmcomponentldInstance*,U32,U32);

void f8928(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f8929(wasmcomponentldInstance*,U32,U32);

U32 f8930(wasmcomponentldInstance*,U32,U32);

U32 f8931(wasmcomponentldInstance*,U32,U32);

U32 f8932(wasmcomponentldInstance*,U32,U32);

U32 f8933(wasmcomponentldInstance*,U32,U32);

void f8934(wasmcomponentldInstance*,U32);

U32 f8935(wasmcomponentldInstance*,U32,U32,U32);

U32 f8936(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8937(wasmcomponentldInstance*,U32);

void f8938(wasmcomponentldInstance*,U32);

void f8939(wasmcomponentldInstance*,U32);

void f8940(wasmcomponentldInstance*,U32);

void f8941(wasmcomponentldInstance*,U32);

void f8942(wasmcomponentldInstance*,U32);

void f8943(wasmcomponentldInstance*,U32);

void f8944(wasmcomponentldInstance*,U32);

void f8945(wasmcomponentldInstance*,U32,U32);

void f8946(wasmcomponentldInstance*,U32);

void f8947(wasmcomponentldInstance*,U32);

void f8948(wasmcomponentldInstance*,U32);

void f8949(wasmcomponentldInstance*,U32);

void f8950(wasmcomponentldInstance*,U32);

void f8951(wasmcomponentldInstance*,U32);

void f8952(wasmcomponentldInstance*,U32);

void f8953(wasmcomponentldInstance*,U32,U32);

void f8954(wasmcomponentldInstance*,U32);

void f8955(wasmcomponentldInstance*,U32,U32);

void f8956(wasmcomponentldInstance*,U32,U32,U32);

void f8957(wasmcomponentldInstance*,U32,U32);

void f8958(wasmcomponentldInstance*,U32,U32);

void f8959(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f8960(wasmcomponentldInstance*,U32,U32);

U32 f8961(wasmcomponentldInstance*,U32,U32);

U32 f8962(wasmcomponentldInstance*,U32,U32);

U32 f8963(wasmcomponentldInstance*,U32,U32);

U32 f8964(wasmcomponentldInstance*,U32,U32,U32);

void f8965(wasmcomponentldInstance*,U32);

void f8966(wasmcomponentldInstance*,U32,U32,U32,U32);

void f8967(wasmcomponentldInstance*,U32,U32);

U32 f8968(wasmcomponentldInstance*,U32,U32);

U32 f8969(wasmcomponentldInstance*,U32,U32);

U32 f8970(wasmcomponentldInstance*,U32,U32);

U32 f8971(wasmcomponentldInstance*,U32,U32);

U32 f8972(wasmcomponentldInstance*,U32,U32);

U32 f8973(wasmcomponentldInstance*,U32,U32);

U32 f8974(wasmcomponentldInstance*,U32,U32);

void f8975(wasmcomponentldInstance*,U32,U32,U32);

U32 f8976(wasmcomponentldInstance*,U32,U32);

void f8977(wasmcomponentldInstance*);

void f8978(wasmcomponentldInstance*);

void f8979(wasmcomponentldInstance*);

void f8980(wasmcomponentldInstance*,U32);

U32 f8981(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f8982(wasmcomponentldInstance*);

U32 f8983(wasmcomponentldInstance*,U32);

U32 f8984(wasmcomponentldInstance*,U64,U32);

U32 f8985(wasmcomponentldInstance*);

void f8986(wasmcomponentldInstance*,U32,U32,U32);

U32 f8987(wasmcomponentldInstance*,U32,U32);

void f8988(wasmcomponentldInstance*,U32);

void f8989(wasmcomponentldInstance*,U32,U32);

U32 f8990(wasmcomponentldInstance*,U32,U32);

void f8991(wasmcomponentldInstance*,U32);

void f8992(wasmcomponentldInstance*,U32);

void f8993(wasmcomponentldInstance*,U32,U32,U32);

U32 f8994(wasmcomponentldInstance*,U32,U32);

U32 f8995(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f8996(wasmcomponentldInstance*,U32,U32,U32);

void f8997(wasmcomponentldInstance*,U32,U32,U32);

void f8998(wasmcomponentldInstance*,U32);

void f8999(wasmcomponentldInstance*,U32);

void f9000(wasmcomponentldInstance*,U32,U32);

U32 f9001(wasmcomponentldInstance*,U32,U32);

U32 f9002(wasmcomponentldInstance*,U32,U32);

void f9003(wasmcomponentldInstance*,U32,U32,U32);

void f9004(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9005(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9006(wasmcomponentldInstance*,U32,U32,U32);

void f9007(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9008(wasmcomponentldInstance*,U32,U32);

void f9009(wasmcomponentldInstance*,U32,U32);

void f9010(wasmcomponentldInstance*,U32,U32);

void f9011(wasmcomponentldInstance*,U32,U32);

void f9012(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9013(wasmcomponentldInstance*,U32,U32);

void f9014(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9015(wasmcomponentldInstance*,U32,U32,U32);

void f9016(wasmcomponentldInstance*,U32,U32,U32);

void f9017(wasmcomponentldInstance*,U32,U32);

U32 f9018(wasmcomponentldInstance*,U32,U32);

U32 f9019(wasmcomponentldInstance*,U32);

void f9020(wasmcomponentldInstance*,U32,U32,U32);

void f9021(wasmcomponentldInstance*,U32,U32);

U32 f9022(wasmcomponentldInstance*,U32,U32);

void f9023(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9024(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9025(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9026(wasmcomponentldInstance*,U32,U32);

void f9027(wasmcomponentldInstance*,U32,U32,U32);

void f9028(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9029(wasmcomponentldInstance*,U32,U32);

U32 f9030(wasmcomponentldInstance*,U32,U32);

void f9031(wasmcomponentldInstance*,U32,U32);

void f9032(wasmcomponentldInstance*,U32,U32);

void f9033(wasmcomponentldInstance*,U32,U32);

void f9034(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9035(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9036(wasmcomponentldInstance*,U32);

void f9037(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9038(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9039(wasmcomponentldInstance*,U32,U32);

void f9040(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9041(wasmcomponentldInstance*);

void f9042(wasmcomponentldInstance*);

U32 f9043(wasmcomponentldInstance*,U32);

void f9044(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9045(wasmcomponentldInstance*,U32,U32);

void f9046(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9047(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9048(wasmcomponentldInstance*,U32,U32,U32);

void f9049(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9050(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9051(wasmcomponentldInstance*,U32,U32);

void f9052(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9053(wasmcomponentldInstance*,U32);

void f9054(wasmcomponentldInstance*,U32,U32,U32);

void f9055(wasmcomponentldInstance*,U32);

U32 f9056(wasmcomponentldInstance*,U32,U32,U32);

U32 f9057(wasmcomponentldInstance*,U32,U32,U32);

U32 f9058(wasmcomponentldInstance*,U32,U32,U32);

void f9059(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9060(wasmcomponentldInstance*,U32,U32,U32);

U32 f9061(wasmcomponentldInstance*);

void f9062(wasmcomponentldInstance*,U32,U32);

U32 f9063(wasmcomponentldInstance*,U32);

void f9064(wasmcomponentldInstance*,U32,U32);

U32 f9065(wasmcomponentldInstance*,U32,U32);

void f9066(wasmcomponentldInstance*,U32,U32,U32);

U32 f9067(wasmcomponentldInstance*,U32,U32);

void f9068(wasmcomponentldInstance*,U32,U32,U32);

void f9069(wasmcomponentldInstance*,U32,U32,U32);

void f9070(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9071(wasmcomponentldInstance*,U32,U32,U32);

void f9072(wasmcomponentldInstance*,U32,U32,U32);

U32 f9073(wasmcomponentldInstance*,U32,U32,U32);

U32 f9074(wasmcomponentldInstance*,U32,U32);

void f9075(wasmcomponentldInstance*,U32,U32);

U32 f9076(wasmcomponentldInstance*,U32,U32);

U32 f9077(wasmcomponentldInstance*,U32,U32);

void f9078(wasmcomponentldInstance*,U32);

void f9079(wasmcomponentldInstance*,U32);

void f9080(wasmcomponentldInstance*);

void f9081(wasmcomponentldInstance*,U32);

void f9082(wasmcomponentldInstance*,U32);

void f9083(wasmcomponentldInstance*,U32,U32,U32);

void f9084(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9085(wasmcomponentldInstance*);

void f9086(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9087(wasmcomponentldInstance*,U32,U32);

void f9088(wasmcomponentldInstance*,U32);

void f9089(wasmcomponentldInstance*,U32);

void f9090(wasmcomponentldInstance*,U32,U32,U32);

void f9091(wasmcomponentldInstance*,U32,U32,U32);

void f9092(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9093(wasmcomponentldInstance*,U32,U32);

void f9094(wasmcomponentldInstance*,U32);

void f9095(wasmcomponentldInstance*,U32,U32);

void f9096(wasmcomponentldInstance*,U32,U32);

U32 f9097(wasmcomponentldInstance*,U32,U32);

void f9098(wasmcomponentldInstance*,U32,U32,U32);

U32 f9099(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9100(wasmcomponentldInstance*,U32,U32);

void f9101(wasmcomponentldInstance*,U32,U32,U32);

void f9102(wasmcomponentldInstance*,U32,U32,U32);

void f9103(wasmcomponentldInstance*,U32,U32,U32);

U32 f9104(wasmcomponentldInstance*,U32);

void f9105(wasmcomponentldInstance*,U32);

void f9106(wasmcomponentldInstance*,U32,U32);

void f9107(wasmcomponentldInstance*,U32,U32);

U32 f9108(wasmcomponentldInstance*,U32,U32);

void f9109(wasmcomponentldInstance*,U32,U32);

void f9110(wasmcomponentldInstance*,U32,U32);

void f9111(wasmcomponentldInstance*,U32,U32);

U32 f9112(wasmcomponentldInstance*,U32,U32);

void f9113(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9114(wasmcomponentldInstance*,U32,U32);

U32 f9115(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9116(wasmcomponentldInstance*,U32,U32);

void f9117(wasmcomponentldInstance*,U32,U32);

void f9118(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9119(wasmcomponentldInstance*,U32,U32,U32);

void f9120(wasmcomponentldInstance*,U32,U32,U32);

void f9121(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9122(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9123(wasmcomponentldInstance*,U32);

void f9124(wasmcomponentldInstance*,U32,U32);

void f9125(wasmcomponentldInstance*,U32,U32);

void f9126(wasmcomponentldInstance*,U32,U32);

U32 f9127(wasmcomponentldInstance*,U32,U32);

U32 f9128(wasmcomponentldInstance*,U32,U32);

U32 f9129(wasmcomponentldInstance*,U32,U32);

void f9130(wasmcomponentldInstance*,U32,U32);

void f9131(wasmcomponentldInstance*,U32,U32);

U32 f9132(wasmcomponentldInstance*,U32,U32);

void f9133(wasmcomponentldInstance*,U32,U32,U32);

void f9134(wasmcomponentldInstance*,U32);

void f9135(wasmcomponentldInstance*,U32,U32,U64);

void f9136(wasmcomponentldInstance*,U32,U32);

void f9137(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9138(wasmcomponentldInstance*,U32,U32,U32,U32,U64);

void f9139(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9140(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9141(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9142(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U64,U64,U32);

void f9143(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9144(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9145(wasmcomponentldInstance*,U32,U32,U32);

U32 f9146(wasmcomponentldInstance*,U32);

U32 f9147(wasmcomponentldInstance*,U32,U32);

U32 f9148(wasmcomponentldInstance*,U32,U32);

U32 f9149(wasmcomponentldInstance*,U32,U32);

U32 f9150(wasmcomponentldInstance*,U32,U32);

U32 f9151(wasmcomponentldInstance*,U32,U32);

U32 f9152(wasmcomponentldInstance*,U32,U32);

U32 f9153(wasmcomponentldInstance*,U32,U32);

U32 f9154(wasmcomponentldInstance*,U32,U32);

U32 f9155(wasmcomponentldInstance*,U32,U32,U32);

U32 f9156(wasmcomponentldInstance*,U32,U32);

U32 f9157(wasmcomponentldInstance*,U32,U32,U32);

U32 f9158(wasmcomponentldInstance*,U32,U32);

void f9159(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9160(wasmcomponentldInstance*,U32,U32);

void f9161(wasmcomponentldInstance*,U32,U32);

void f9162(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f9163(wasmcomponentldInstance*,U32,U32);

U32 f9164(wasmcomponentldInstance*,U32,U32);

U32 f9165(wasmcomponentldInstance*,U32,U32);

U32 f9166(wasmcomponentldInstance*,U32,U32);

U32 f9167(wasmcomponentldInstance*,U32,U32);

U32 f9168(wasmcomponentldInstance*,U32,U32);

void f9169(wasmcomponentldInstance*,U32,U32);

void f9170(wasmcomponentldInstance*,U32,U32);

void f9171(wasmcomponentldInstance*,U32,U32);

void f9172(wasmcomponentldInstance*,U32,U32);

void f9173(wasmcomponentldInstance*,U32,U32,U32);

void f9174(wasmcomponentldInstance*,U32,U32);

void f9175(wasmcomponentldInstance*,U32,U32);

void f9176(wasmcomponentldInstance*,U32);

U32 f9177(wasmcomponentldInstance*,U32,U32);

U32 f9178(wasmcomponentldInstance*,U32);

U32 f9179(wasmcomponentldInstance*,U32);

U32 f9180(wasmcomponentldInstance*,U32,U32);

U32 f9181(wasmcomponentldInstance*,U32,U32);

U32 f9182(wasmcomponentldInstance*,U32,U32);

U32 f9183(wasmcomponentldInstance*,U32,U64);

U32 f9184(wasmcomponentldInstance*,U32);

U32 f9185(wasmcomponentldInstance*,U32);

U32 f9186(wasmcomponentldInstance*,U32);

U32 f9187(wasmcomponentldInstance*,U32);

void f9188(wasmcomponentldInstance*,U32,U32);

void f9189(wasmcomponentldInstance*,U32,U32);

U32 f9190(wasmcomponentldInstance*,U32);

U32 f9191(wasmcomponentldInstance*,U32);

U32 f9192(wasmcomponentldInstance*,U32);

U32 f9193(wasmcomponentldInstance*,U32);

U32 f9194(wasmcomponentldInstance*,U32,U32);

U32 f9195(wasmcomponentldInstance*,U32);

void f9196(wasmcomponentldInstance*,U32,U32,U32);

void f9197(wasmcomponentldInstance*,U32,U32,U32);

U32 f9198(wasmcomponentldInstance*,U32,U32);

U32 f9199(wasmcomponentldInstance*,U32,U32);

void f9200(wasmcomponentldInstance*,U32,U32);

void f9201(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9202(wasmcomponentldInstance*,U32);

U32 f9203(wasmcomponentldInstance*,U32);

U32 f9204(wasmcomponentldInstance*,U32,U32,U32);

void f9205(wasmcomponentldInstance*,U32);

void f9206(wasmcomponentldInstance*,U32);

U32 f9207(wasmcomponentldInstance*,U32,U32);

U32 f9208(wasmcomponentldInstance*,U32,U32);

void f9209(wasmcomponentldInstance*,U32,U32);

U32 f9210(wasmcomponentldInstance*,U32,U32,U32);

U32 f9211(wasmcomponentldInstance*,U32,U32);

U32 f9212(wasmcomponentldInstance*,U32);

void f9213(wasmcomponentldInstance*,U32);

void f9214(wasmcomponentldInstance*);

void f9215(wasmcomponentldInstance*);

U32 f9216(wasmcomponentldInstance*,U32,U32);

U32 f9217(wasmcomponentldInstance*,U32,U32);

U32 f9218(wasmcomponentldInstance*,U32);

U32 f9219(wasmcomponentldInstance*,U32,U32);

U32 f9220(wasmcomponentldInstance*,U32,U32);

U32 f9221(wasmcomponentldInstance*,U32,U32,U32);

void f9222(wasmcomponentldInstance*,U32);

void f9223(wasmcomponentldInstance*);

U32 f9224(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9225(wasmcomponentldInstance*,U32,U32);

U32 f9226(wasmcomponentldInstance*,U32);

void f9227(wasmcomponentldInstance*);

U32 f9228(wasmcomponentldInstance*,U32,U32);

U32 f9229(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9230(wasmcomponentldInstance*,U32,U32,U32);

U32 f9231(wasmcomponentldInstance*,U32);

U32 f9232(wasmcomponentldInstance*,U32);

void f9233(wasmcomponentldInstance*);

void f9234(wasmcomponentldInstance*);

void f9235(wasmcomponentldInstance*,U32);

U32 f9236(wasmcomponentldInstance*,U32,U32,U32);

U32 f9237(wasmcomponentldInstance*,U32,U32,U32);

U32 f9238(wasmcomponentldInstance*,U32,U32,U32);

U32 f9239(wasmcomponentldInstance*,U32,U32);

U32 f9240(wasmcomponentldInstance*,U32,U32);

U32 f9241(wasmcomponentldInstance*,U32,U32);

U32 f9242(wasmcomponentldInstance*,U32);

U32 f9243(wasmcomponentldInstance*,U32,U32);

U32 f9244(wasmcomponentldInstance*,U32,U32);

U32 f9245(wasmcomponentldInstance*,U32);

U32 f9246(wasmcomponentldInstance*,U32,U32,U32);

U32 f9247(wasmcomponentldInstance*,U32);

U32 f9248(wasmcomponentldInstance*,U32,U32,U32);

U32 f9249(wasmcomponentldInstance*,U32,U32);

void f9250(wasmcomponentldInstance*,U32);

U32 f9251(wasmcomponentldInstance*,U32,U32);

U32 f9252(wasmcomponentldInstance*,U32,U32);

void f9253(wasmcomponentldInstance*,U32);

void f9254(wasmcomponentldInstance*,U32,U32);

void f9255(wasmcomponentldInstance*,U32,U32,U32);

void f9256(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9257(wasmcomponentldInstance*,U32,U32,U32);

void f9258(wasmcomponentldInstance*,U32,U32);

void f9259(wasmcomponentldInstance*,U32,U32);

U32 f9260(wasmcomponentldInstance*,U32,U32);

U32 f9261(wasmcomponentldInstance*,U32,U32);

void f9262(wasmcomponentldInstance*,U32,U32,U32);

void f9263(wasmcomponentldInstance*,U32,U32);

void f9264(wasmcomponentldInstance*,U32,U32,U32);

void f9265(wasmcomponentldInstance*,U32,U32);

void f9266(wasmcomponentldInstance*,U32,U32,U32);

void f9267(wasmcomponentldInstance*,U32,U32,U32);

void f9268(wasmcomponentldInstance*,U32,U32,U32);

void f9269(wasmcomponentldInstance*,U32,U32,U32);

U32 f9270(wasmcomponentldInstance*,U32,U32,U32);

U32 f9271(wasmcomponentldInstance*,U32,U32);

void f9272(wasmcomponentldInstance*,U32,U32,U32);

void f9273(wasmcomponentldInstance*,U32,U32,U32);

void f9274(wasmcomponentldInstance*,U32,U32,U32);

void f9275(wasmcomponentldInstance*,U32,U32,U32);

void f9276(wasmcomponentldInstance*,U32,U32,U32);

void f9277(wasmcomponentldInstance*,U32,U32,U32);

U64 f9278(wasmcomponentldInstance*,U32);

void f9279(wasmcomponentldInstance*,U32,U32);

void f9280(wasmcomponentldInstance*,U32,U32,U32);

void f9281(wasmcomponentldInstance*,U32,U32);

void f9282(wasmcomponentldInstance*,U32,U32,U32);

void f9283(wasmcomponentldInstance*,U32,U32,U32);

void f9284(wasmcomponentldInstance*,U32,U64,U64);

void f9285(wasmcomponentldInstance*,U32,U64,U64);

void f9286(wasmcomponentldInstance*,U32,U32,U32);

U32 f9287(wasmcomponentldInstance*,U32,U32,U32);

void f9288(wasmcomponentldInstance*,U32,U32,U32);

void f9289(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9290(wasmcomponentldInstance*,U32,U32);

U32 f9291(wasmcomponentldInstance*,U32,U32,U32);

U32 f9292(wasmcomponentldInstance*,U32,U32);

void f9293(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9294(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9295(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9296(wasmcomponentldInstance*,U32);

void f9297(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9298(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U64,U64,U64);

void f9299(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f9300(wasmcomponentldInstance*,U32,U32);

U32 f9301(wasmcomponentldInstance*,U32,U32);

void f9302(wasmcomponentldInstance*,U32,U32);

U32 f9303(wasmcomponentldInstance*,U32,U32);

U32 f9304(wasmcomponentldInstance*,U32,U32,U32);

U32 f9305(wasmcomponentldInstance*,U32,U32);

U32 f9306(wasmcomponentldInstance*,U32,U32);

U32 f9307(wasmcomponentldInstance*,U32,U32);

U32 f9308(wasmcomponentldInstance*,U32,U32);

U32 f9309(wasmcomponentldInstance*,U32,U32,U32);

void f9310(wasmcomponentldInstance*,U32,U32);

U32 f9311(wasmcomponentldInstance*,U32,U32);

U32 f9312(wasmcomponentldInstance*,U32,U32);

void f9313(wasmcomponentldInstance*,U32,U32,U32);

U32 f9314(wasmcomponentldInstance*,U32,U32);

U32 f9315(wasmcomponentldInstance*,U32,U32);

U32 f9316(wasmcomponentldInstance*,U32,U32);

U32 f9317(wasmcomponentldInstance*,U32,U32);

void f9318(wasmcomponentldInstance*,U32);

void f9319(wasmcomponentldInstance*,U32);

U32 f9320(wasmcomponentldInstance*,U32,U32);

U32 f9321(wasmcomponentldInstance*,U32);

U32 f9322(wasmcomponentldInstance*,U32);

U32 f9323(wasmcomponentldInstance*,U32,U32);

U32 f9324(wasmcomponentldInstance*,U32,U32,U32);

void f9325(wasmcomponentldInstance*,U32,U32,U32);

void f9326(wasmcomponentldInstance*,U32,U32,U32);

U32 f9327(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9328(wasmcomponentldInstance*,U32,U32);

void f9329(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9330(wasmcomponentldInstance*,U32,U32,U32);

U32 f9331(wasmcomponentldInstance*,U32,U32);

U32 f9332(wasmcomponentldInstance*,U32,U32);

void f9333(wasmcomponentldInstance*,U32);

void f9334(wasmcomponentldInstance*,U32,U32,U32);

U32 f9335(wasmcomponentldInstance*,U32,U32);

void f9336(wasmcomponentldInstance*,U32);

U32 f9337(wasmcomponentldInstance*,U32,U32);

void f9338(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9339(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f9340(wasmcomponentldInstance*,U32,U32);

U32 f9341(wasmcomponentldInstance*,U32,U32);

U32 f9342(wasmcomponentldInstance*,U32,U32,U32);

U32 f9343(wasmcomponentldInstance*,U32,U32);

U32 f9344(wasmcomponentldInstance*,U32);

U32 f9345(wasmcomponentldInstance*,U32,U32,U32);

U32 f9346(wasmcomponentldInstance*,U32);

U32 f9347(wasmcomponentldInstance*,U32,U32,U32);

U32 f9348(wasmcomponentldInstance*,U32);

U32 f9349(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9350(wasmcomponentldInstance*,U32,U32,U32);

U32 f9351(wasmcomponentldInstance*,U32);

U32 f9352(wasmcomponentldInstance*,U32,F64,U32,U32);

U32 f9353(wasmcomponentldInstance*,U32,U32);

U32 f9354(wasmcomponentldInstance*,U32,F64,U32,U32);

U32 f9355(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32);

U32 f9356(wasmcomponentldInstance*,U32,U32);

U32 f9357(wasmcomponentldInstance*,U32,U32);

U32 f9358(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9359(wasmcomponentldInstance*,U32,U32,U32);

U32 f9360(wasmcomponentldInstance*,U32,U32,U32);

U32 f9361(wasmcomponentldInstance*,U32);

void f9362(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9363(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f9364(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f9365(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f9366(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f9367(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f9368(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

void f9369(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9370(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9371(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f9372(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32);

U32 f9373(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32,U32);

void f9374(wasmcomponentldInstance*,U32,U32);

void f9375(wasmcomponentldInstance*,U32,U32);

U32 f9376(wasmcomponentldInstance*,U32,U32);

U32 f9377(wasmcomponentldInstance*,U32,U32);

U32 f9378(wasmcomponentldInstance*,U32,U32,U32);

void f9379(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9380(wasmcomponentldInstance*,U32,U32,U32);

U32 f9381(wasmcomponentldInstance*,U32,U32);

U32 f9382(wasmcomponentldInstance*,U32,U32);

void f9383(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9384(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9385(wasmcomponentldInstance*,U32);

void f9386(wasmcomponentldInstance*);

void f9387(wasmcomponentldInstance*,U32,U32,U32);

void f9388(wasmcomponentldInstance*,U32,U32,U32);

void f9389(wasmcomponentldInstance*,U32,U32,U32);

void f9390(wasmcomponentldInstance*,U32);

void f9391(wasmcomponentldInstance*,U32);

U32 f9392(wasmcomponentldInstance*,U32,U32);

void f9393(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

U32 f9394(wasmcomponentldInstance*,U32,U32);

U32 f9395(wasmcomponentldInstance*,U32,U32);

void f9396(wasmcomponentldInstance*,U32,U32,U32,U32,U32);

void f9397(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9398(wasmcomponentldInstance*,U32,U32,U32);

U32 f9399(wasmcomponentldInstance*,U32,U32);

U32 f9400(wasmcomponentldInstance*,U32,U32,U32,U32,U32,U32,U32);

U32 f9401(wasmcomponentldInstance*,U32,U32);

U32 f9402(wasmcomponentldInstance*,U32,U32);

void f9403(wasmcomponentldInstance*,U32,U32,U32);

void f9404(wasmcomponentldInstance*,U32,U32,U32);

U32 f9405(wasmcomponentldInstance*,U64,U32);

U32 f9406(wasmcomponentldInstance*,U32,U32);

U32 f9407(wasmcomponentldInstance*,U32,U32);

U32 f9408(wasmcomponentldInstance*,U32,U32);

U32 f9409(wasmcomponentldInstance*,U32,U32);

U32 f9410(wasmcomponentldInstance*,U32,U32);

U32 f9411(wasmcomponentldInstance*,U32,U32);

void f9412(wasmcomponentldInstance*,U32,U32,U32,U32);

void f9413(wasmcomponentldInstance*,U32,U64,U32,U32);

void f9414(wasmcomponentldInstance*,U32,U32,U32,U32);

U32 f9415(wasmcomponentldInstance*,U32,U32);

U32 f9416(wasmcomponentldInstance*,U32,U32);

U32 f9417(wasmcomponentldInstance*,U32,U32);

U32 f9418(wasmcomponentldInstance*,U32,U32);

U32 f9419(wasmcomponentldInstance*,U32,U32);

U32 f9420(wasmcomponentldInstance*,U32);

U32 f9421(wasmcomponentldInstance*,U32);

U32 f9422(wasmcomponentldInstance*,U32);

U32 f9423(wasmcomponentldInstance*,U32);

U32 f9424(wasmcomponentldInstance*,U32);

void f9425(wasmcomponentldInstance*,U32,U32);

void f9426(wasmcomponentldInstance*,U32,U64,U64,U64,U64);

void f9427(wasmcomponentldInstance*,U32,U64,U64,U32);

wasmMemory*wasmcomponentld_memory(wasmcomponentldInstance* i);

void wasmcomponentld__start(wasmcomponentldInstance*i);

U32 wasmcomponentld____main_void(wasmcomponentldInstance*i);

void wasmcomponentldInstantiate(wasmcomponentldInstance* instance, void* resolve(const char* module, const char* name));

void wasmcomponentldFreeInstance(wasmcomponentldInstance* instance);

#ifdef __cplusplus
}
#endif

#endif /* wasmcomponentld_H */

