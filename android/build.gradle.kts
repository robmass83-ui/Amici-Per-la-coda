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
        afterEvaluate {
            val android = extensions.getByName("android")
            val setter = android.javaClass.methods.firstOrNull { method ->
                method.parameterCount == 1 &&
                    (method.name == "setCompileSdk" || method.name == "setCompileSdkVersion")
            }
            val type = setter?.parameterTypes?.firstOrNull()
            when {
                setter == null -> Unit
                type == Int::class.javaPrimitiveType -> setter.invoke(android, 36)
                type == Integer::class.java -> setter.invoke(android, Integer.valueOf(36))
                type == String::class.java -> setter.invoke(android, "android-36")
                else -> setter.invoke(android, 36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
