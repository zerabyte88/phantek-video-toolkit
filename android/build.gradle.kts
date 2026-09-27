allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            dependencySubstitution {
                substitute(module("com.arthenica:ffmpeg-kit-full-gpl:6.0-2"))
                    .using(module("dev.ffmpegkit-maintained:ffmpeg-kit-full-gpl:6.0.4"))
                    .because("com.arthenica binaries were retired from Maven Central")
            }
            eachDependency {
                if (requested.group == "com.arthenica" && requested.name.startsWith("ffmpeg-kit")) {
                    useTarget("dev.ffmpegkit-maintained:${requested.name}:6.0.4")
                    because("com.arthenica binaries were retired from Maven Central")
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
