def GetPrefix(file){
    return file.toString().take(file.toString().lastIndexOf('.'))
}

def GetJuliaCmd(cpus){
    def sysimageFile = new File("/opt/TopMedImputation/sysimage.so")
    if (workflow.profile == "dev") {
        return "julia --project=/opt/genomicc-workflows --startup-file=no --threads=${cpus} /opt/genomicc-workflows/bin/genomicc.jl"
    }
    else if (workflow.profile == "devsingularity"){
        return "JULIA_CPU_TARGET=generic JULIA_DEPOT_PATH=/tmp:\$JULIA_DEPOT_PATH julia --project=/opt/genomicc-workflows --startup-file=no --threads=${cpus} /opt/genomicc-workflows/bin/genomicc.jl"
    }
    else {
        return "TEMPD=\$(mktemp -d) && JULIA_DEPOT_PATH=\$TEMPD:\$JULIA_DEPOT_PATH julia --project=/opt/genomicc-workflows --startup-file=no --threads=${cpus} --sysimage=${sysimageFile} /opt/genomicc-workflows/bin/genomicc.jl"
    }        
}