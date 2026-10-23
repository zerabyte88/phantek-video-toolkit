allprojects {
    extra.set("ffmpegKitPackage", "full-gpl")
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            dependencySubstitution {
                substitute(module("com.arthenica:ffmpeg-kit-full-gpl:6.0-2"))
                    .using(module("dev.ffmpegkit-maintained:ffmpeg-kit-full-gpl:8.1.9"))
                    .because("com.arthenica binaries were retired from Maven Central; upgrade to FFmpeg 8.1")
            }
            eachDependency {
                if (requested.group == "com.arthenica" && requested.name.startsWith("ffmpeg-kit")) {
                    useTarget("dev.ffmpegkit-maintained:${requested.name}:8.1.9")
                    because("com.arthenica binaries were retired from Maven Central; upgrade to FFmpeg 8.1")
                }
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
