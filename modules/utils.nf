def GetPrefix(file){
    return file.toString().take(file.toString().lastIndexOf('.'))
}

def GetJuliaCmd(cpus){
    def sysimageFile = new File("/opt/TopMedImputation/sysimage.so")
    if (workflow.profile == "dev") {
        return "julia --project=/opt/TopMedImputation --startup-file=no --threads=${cpus} /opt/TopMedImputation/bin/impute.jl"
    }
    else if (workflow.profile == "devsingularity"){
        return "JULIA_CPU_TARGET=generic JULIA_DEPOT_PATH=/tmp:\$JULIA_DEPOT_PATH julia --project=/opt/TopMedImputation --startup-file=no --threads=${cpus} /opt/TopMedImputation/bin/impute.jl"
    }
    else {
        return "TEMPD=\$(mktemp -d) && JULIA_DEPOT_PATH=\$TEMPD:\$JULIA_DEPOT_PATH julia --project=/opt/TopMedImputation --startup-file=no --threads=${cpus} --sysimage=${sysimageFile} /opt/TopMedImputation/bin/impute.jl"
    }        
}