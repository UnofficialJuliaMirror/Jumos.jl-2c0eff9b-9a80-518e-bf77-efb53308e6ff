# Testing potentials

harmonic = Harmonic(30, 2.0, -0.5)

@test harmonic(2.0) == -0.5
@test harmonic(4.0) == 59.5
@test force(harmonic, 2.0) == 0.0
@test force(harmonic, 3.0) == -30.0

lj = LennardJones(0.4, 2.0)
@test lj(2.0) == 0.0
@test lj(2.5) == -0.3094792372224001
# TODO: get LJ minimum
#@test force(lj, 2.0) == 0.0
#@test force(lj, 3.0) == 30.0

f(x) = 3*(x-3.5)^4
g(x) = 12*(x-3.5)^3

user_1 = UserPotential(f, g)
user_2 = UserPotential(f)

@test user_1(3.0) == f(3)
@test user_2(3.0) == f(3)
@test force(user_1, 3.0) == g(3)
@test isapprox(force(user_1, 3.0), g(3))

short = Potential(lj, cutoff=8.0)
@test short.cutoff == 8.0
@test short.e_cutoff == lj(8.0)
@test short(9) == 0.0
@test short(3.) == lj(3.0) + short.e_cutoff

sim = Simulation("MD", 1.0)

set_cell(sim, (8.0,))

top = Topology(2)
top[1] = Atom("He")
top[2] = Atom("He")

frame = Frame(top)
frame.positions[1] = [2., 2., 2.] + 0.1 .* rand(3)
frame.positions[2] = [2., 2., 4.] + 0.1 .* rand(3)
frame.cell = sim.cell

set_frame(sim, frame)

create_velocities(sim, 300)

add_interaction(sim, Harmonic(30, 2.0, -0.5), "He")

out_trajectory = TrajectoryOutput("traj.xyz", 1)
add_output(sim, out_trajectory)

run!(sim, 500)
