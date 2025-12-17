#[compute]
#version 450

// Parallel stuff running on the GPU
// 8x8 threads so 64 threads in a workgroup
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Input maps, two pressures to use old and new, writes into pressure_new
layout(set = 0, binding = 0, std430) restrict buffer PressureOld {
    float pressure_old[];
};
layout(set = 0, binding = 1, std430) restrict buffer PressureNew {
    float pressure_new[];
};
layout(set = 0, binding = 2, std430) restrict buffer VelocityXBuffer {
    float vel_x[];
};
layout(set = 0, binding = 3, std430) restrict buffer VelocityYBuffer {
    float vel_y[];
};

// Parameters passed each frame
layout(push_constant, std430) uniform Params {
    int grid_width;
    int grid_height;
    float time;
    // Apparently theres dumb rule that it has to be 32??? idk we'll see
    float _padding;
} params;

const float C = 1.0; // m/s of soundwaves
const float AIR_DENSITY = 1.225; // kg/m^3
const float DX = 1.0; // Grid spacing (normalized)
const float DT = .001; // Time step
const float COURANT = C * DT / DX; // Must be < 1 for stability (CFL condition, whatever that menas)

// 0 is no damping, 1 is full damping
const float DAMPING = 0.01;

int get_index(ivec2 pos) {
    return pos.y * params.grid_width + pos.x;
}
float sample_pressure(ivec2 pos) {
    pos = clamp(pos, ivec2(0), ivec2(params.grid_width - 1, params.grid_height - 1));
    return pressure_old[get_index(pos)];
}
float sample_vel_x(ivec2 pos) {
    pos = clamp(pos, ivec2(0), ivec2(params.grid_width - 1, params.grid_height - 1));
    return vel_x[get_index(pos)];
}
float sample_vel_y(ivec2 pos) {
    pos = clamp(pos, ivec2(0), ivec2(params.grid_width - 1, params.grid_height - 1));
    return vel_y[get_index(pos)];
}

void main() {
    // Which cell in the grid are we working on?
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    
    // Check out of bounds and stuff
    if (pos.x >= params.grid_width || pos.y >= params.grid_height) {
        return;
    }
    
    int index = get_index(pos);
    
    // Simple wave equation: p_new = 2*p - p_old + c^2 * laplacian(p)
    // We'll use the current pressure as both p and p_old for simplicity
    float p_center = sample_pressure(pos);
    float p_left = sample_pressure(pos + ivec2(-1, 0));
    float p_right = sample_pressure(pos + ivec2(1, 0));
    float p_top = sample_pressure(pos + ivec2(0, -1));
    float p_bottom = sample_pressure(pos + ivec2(0, 1));
    
    // Laplacian (second derivative)
    float laplacian = p_left + p_right + p_top + p_bottom - 4.0 * p_center;
    float laplacian_scaled = (C * C * DT * DT / (DX * DX)) * laplacian;
    
    // Wave equation update
    float new_pressure = 2 * p_center - pressure_new[index] + C * C * laplacian_scaled;
    
    // Apply damping
    new_pressure *= (1.0 - DAMPING);
    
    // // Add a oscillating source to see stuff change
    ivec2 source_pos = ivec2(params.grid_width / 2, params.grid_height / 2);
    if (pos == source_pos) {
        new_pressure += sin(2.0 * 3.14159 * 440.0 * params.time);
    }
    
    
    pressure_new[index] = new_pressure;
    
}