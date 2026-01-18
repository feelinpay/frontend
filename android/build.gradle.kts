allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-nowarn")
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

rootProject.buildDir = File("../build")
subprojects {
    project.buildDir = File("${rootProject.buildDir}/${project.name}")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
