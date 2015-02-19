# Copyright (c) Guillaume Fraux 2014
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# ============================================================================ #
#                       Compute interesting values
# ============================================================================ #

import Base: write
export BaseOutput
export TrajectoryOutput, CustomOutput, EnergyOutput

# abstract BaseOutput -> Defined in MolecularDynamics.jl

function setup(::BaseOutput, ::Simulation)
    return nothing
end

const EOL="\n"
const TAB="\t"

type OutputFrequency
    frequency::Int
    current::Int
end

OutputFrequency(freq::Int) = OutputFrequency(freq, 0)
OutputFrequency() = OutputFrequency(1)
function Base.step(out::BaseOutput)
    out.frequency.current += 1
end
function Base.done(out::BaseOutput)
    if out.frequency.current == out.frequency.frequency
        out.frequency.current = 0
        return true
    end
    return false
end

# ============================================================================ #

@doc "
Write the trajectory to a file. The trajectory format is guessed from the extension.
" ->
type TrajectoryOutput <: BaseOutput
    writer::Writer
    frequency::OutputFrequency
end

function TrajectoryOutput(filename::String, frequency=1)
    writer = Writer(filename)
    return TrajectoryOutput(writer, OutputFrequency(frequency))
end

function write(out::TrajectoryOutput, context::Dict)
    write(out.writer, context[:frame])
end

# ============================================================================ #

@doc "
Write values to a file, each line containing the results of string
interpolation of the `values` vector of symbol.

`CustomOutput(filename::String, values::Vector{Symbol}[, frequency=1; header])`
    Create a Custom output of `values`, with write frequency of `frequency`.
    The `header` is written on the top of the file, and contains by default
    the names from `values`
" ->
type CustomOutput <: BaseOutput
    file::IOStream
    values::Vector{Symbol}
    frequency::OutputFrequency
end

function CustomOutput(filename::String, values::Vector{Symbol}, frequency=1;
                       header="# Generated by Jumos package")
    file = open(filename, "w")
    write(file, header * EOL)
    s = "# "
    for name in values
        s *= string(name) * "   "
    end
    write(file, s * EOL)
    return CustomOutput(file, values, OutputFrequency(frequency))
end

function write(out::CustomOutput, context::Dict)
    s = ""
    for value in out.values
        if haskey(context, value)
            s *= TAB * context[value]
        else
            error("Value not found for output: $(KeyError.key)")
        end
    end
    write(out.file, s * EOL)
end

# ============================================================================ #

@doc "
Output the energy of a simulation to a file.
" ->
type EnergyOutput <: BaseOutput
    file::IOStream
    frequency::OutputFrequency
end

function EnergyOutput(filename::String, frequency=1)
    file = open(filename, "w")
    write(file, "# Energy from Jumos simulation" * EOL)
    write(file, "# step\tEkin(kJ/mol)\tEpot(kJ/mol)\tEtot(kJ/mol)\tT(K)" * EOL)
    return EnergyOutput(file, OutputFrequency(frequency))
end

function write(out::EnergyOutput, context::Dict)
    T = context[:temperature]
    Ekin = context[:E_kinetic]
    Epot = context[:E_potential]
    Etot = context[:E_total]
    step = context[:step]
    s = "$step\t$Ekin\t$Epot\t$Etot\t$T"
    write(out.file, s * EOL)
end

function setup(::EnergyOutput, sim::Simulation)
    if !have_compute(sim, TemperatureCompute)
        push!(sim.computes, TemperatureCompute())
    end
    if !have_compute(sim, EnergyCompute)
        push!(sim.computes, EnergyCompute())
    end
end
