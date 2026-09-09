allprojects {
    repositories {
        google()
        mavenCentral()
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

// file_picker still ships compileSdk 34; flutter_plugin_android_lifecycle wants 36.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.getByName("android")
        android.javaClass.methods
            .firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
            ?.invoke(android, 36)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
