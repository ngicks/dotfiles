import path from "node:path";

import { basePaths } from "#/lib/config.ts";

export const openJdkBasePath = path.join(basePaths.home, ".local", "openjdk");

export const openJdkUrls = {
  24:
    "https://download.java.net/java/GA/jdk24/1f9ff9062db4449d8ca828c504ffae90/36/GPL/openjdk-24_${os}-${arch}_bin.${ext}",
  23:
    "https://download.java.net/java/GA/jdk23.0.2/6da2a6609d6e406f85c491fcb119101b/7/GPL/openjdk-23.0.2_${os}-${arch}_bin.${ext}",
  22:
    "https://download.java.net/java/GA/jdk22.0.2/c9ecb94cd31b495da20a27d4581645e8/9/GPL/openjdk-22.0.2_${os}-${arch}_bin.${ext}",
  21:
    "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_${os}-${arch}_bin.${ext}",
  20:
    "https://download.java.net/java/GA/jdk20.0.2/6e380f22cbe7469fa75fb448bd903d8e/9/GPL/openjdk-20.0.2_${os}-${arch}_bin.${ext}",
  19:
    "https://download.java.net/java/GA/jdk19.0.1/afdd2e245b014143b62ccb916125e3ce/10/GPL/openjdk-19.0.1_${os}-${arch}_bin.${ext}",
  18:
    "https://download.java.net/java/GA/jdk18.0.2/f6ad4b4450fd4d298113270ec84f30ee/9/GPL/openjdk-18.0.2_${os}-${arch}_bin.${ext}",
  17:
    "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_${os}-${arch}_bin.${ext}",
  16:
    "https://download.java.net/java/GA/jdk16.0.2/d4a915d82b4c4fbb9bde534da945d746/7/GPL/openjdk-16.0.2_${os}-${arch}_bin.${ext}",
  15:
    "https://download.java.net/java/GA/jdk15.0.2/0d1cfde4252546c6931946de8db48ee2/7/GPL/openjdk-15.0.2_${os}-${arch}_bin.${ext}",
  14:
    "https://download.java.net/java/GA/jdk14.0.2/205943a0976c4ed48cb16f1043c5c647/12/GPL/openjdk-14.0.2_${os}-${arch}_bin.${ext}",
  13:
    "https://download.java.net/java/GA/jdk13.0.2/d4173c853231432d94f001e99d882ca7/8/GPL/openjdk-13.0.2_${os}-${arch}_bin.${ext}",
  12:
    "https://download.java.net/java/GA/jdk12.0.2/e482c34c86bd4bf8b56c0b35558996b9/10/GPL/openjdk-12.0.2_${os}-${arch}_bin.${ext}",
  11:
    "https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_${os}-${arch}_bin.${ext}",
  10:
    "https://download.java.net/java/GA/jdk10/10.0.2/19aef61b38124481863b1413dce1855f/13/openjdk-10.0.2_${os}-${arch}_bin.${ext}",
  9: "https://download.java.net/java/GA/jdk9/9.0.4/binaries/openjdk-9.0.4_${os}-${arch}_bin.${ext}",
};
