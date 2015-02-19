facts("Trajectory IO") do
    TRAJ_DIR = joinpath(dirname(@__FILE__), "trjs")

    context("NetCDF") do
        traj = Reader("$TRAJ_DIR/water.nc")
        topology = read_topology("$TRAJ_DIR/water.lmp")
        uni = Universe(UnitCell(), topology)
        read_next_frame!(traj, uni)

        @fact length(uni.frame.positions) => traj.natoms

        @fact uni.topology[1].label => :O
        @fact uni.topology[2].label => :H
        @fact uni.topology[1].mass => 15.999
        @fact size(uni.topology.templates, 1) => 2

        close(traj)
    end

    context("XYZ") do
        tmp = tempname()
        outtraj = Writer("$tmp.xyz")
        traj = Reader("$TRAJ_DIR/water.xyz")
        uni = Universe(traj.natoms)

        context("Reading") do
            read_frame!(traj, 50, uni)
            @fact length(uni.frame.positions) => traj.natoms

            @fact uni.topology[4].label => :O
            @fact uni.topology[4].mass => ATOMIC_MASSES[:O].val
        end

        context("Writing") do
            read_frame!(traj, 50, uni)
            write(outtraj, uni)
            @pending "check the first and last lines of the writen traj" => :TODO
        end

        close(traj)
        close(outtraj)
        rm("$tmp.xyz")
    end

end
