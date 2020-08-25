#計算に関係ないパッケージ
using Pkg

include("parameter.jl")

#計算に使うパッケージ
using LinearAlgebra
using Plots
using KTOptical
using .Param
#using FileIO
# 計算条件###################
#計算レンジ 

crange = Param.crange(x = 25um, y = 25um, z = 100um, t = 10)
#計算ステップ
step = Param.step(x = 0.1um, y = 0.1um, z = 0.1um)
Nx = Int(crange.x / step.x)
Ny = Int(crange.y / step.y)
Nz = Int(crange.z / step.z)
Nt = Int(crange.t / step.t)
N = Param.N(Nx,Ny,Nz,Nt)

#材料情報
material = Param.materiarl(nb = 1.5, Δn0 = 0.01, τ = 0.1,α = 0)
mode = Param.vortex_mode(l=1, p=0)

#ビーム情報
beam = Param.beam(w = 20um, U0 = 100.0, wavelength = 1.064um)

println("計算環境")
versioninfo()
Pkg.status()

println("計算条件")
@show crange
@show step
@show N
@show material
@show mode
@show beam

println("//////////////////////////////")
function returnPades(T::Integer,N::Integer)
end


#ADIの未知数Y方向 定数X方向 差分
@time function calcStep1(F_k11, F_kp12)
    k0 = 2π / beam.wavelength
    a = -1/(step.y)^2
    b = 1im*4*k0*retN()/step.z + 2/step.y^2 - k0^2(material.n^2-retN()^2)/2
    c = 1/(step.x)^2
    d = 1im*4*k0*retN()/step.z - 2/step.x^2 + k0^2(material.n^2-retN()^2)/2
    B = zeros(ComplexF64,Nx,1)
    
    #透明境界条件を使う場合、2からN-1 でいいのかしら？
    for j in 2:N.y-1
        #Ax=BのA, z = k+1を作る。
        A = diagm(N.y,N.y, fill(b, N.y)) + diagm(N.y, N.y, 1 => fill(a,N.y-1)) + diagm(N.y,N.y, -1 => fill(a,N.y-1))
        
        for i in 2:N.x-1
            B[i] = c*F_k11[i]+d(F_k11[N.y*j + i-1]+F_k11[N.y*j + i+1])
        end
        F_kp12[:,j] = B\A
    end
    

    return F_kp12
end

#ADIの未知数X方向 定数Y方向 差分
function calcStep2(F_k12, F_kp21)
    for i in range(1,length = N.x)
        for j in range(1,length = N.y)
            continue
        end
    end
    boundary_set(u,k,F_kp21)
    return F_kp21
end

function retN()
    return 1
end

# 試験的。BPMのモード測定を使う
function showMode()
end


function boundary_set(u,k,array)
end

@time function initial_set(M, B ,F0)
    KTOptical.setParam(B.w, 0, B.wavelength)
    x = range(-crange.x/2, crange.x/2 ,step = step.x)
    y = range(-crange.y/2, crange.y/2 ,step = step.y)

    E = LG_I.(M.l, M.p,x,y')
    return E

end

function main()
    #セル個数
    F0 = zeros(N.x, N.y, N.z)
    E = initial_set(mode, beam, F0)
    gr()
    x = range(-crange.x/2, crange.x/2 ,step = step.x)

    F_result = zeros(Float64,(N.x,N.y,N.z));
    #F_k_1stは現在のF_k
    #F_k_2ndは更新されたF_k
    @show N.x * N.y, N.x* N.y
    F_k_1st = zeros(N.x, N.y)

    F_k_2nd = zeros(N.x, N.y)
#    #左辺は更新されたF_k_1stが入る。
    #F_k_2ndは関数内部で毎回宣言した方がいいのか、
    #それとも一度宣言して引数として与えた方がいいのか（いまはこれ
    #は要検証。
    F_k_1st = calcStep1(F_k_1st,F_k_2nd)
    F_k_1st = calcStep2(F_k_1st,F_k_2nd)
    #push(F_k_1st )
end

@time main()