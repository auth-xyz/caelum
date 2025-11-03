#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>

#define WIDTH 80
#define HEIGHT 24
#define PLANET_RADIUS 8
#define RING_INNER 12
#define RING_OUTER 16
#define PI 3.14159265359

typedef struct {
    float x, y, z;
} Point3D;

char density_chars[] = " .:-=+*#%@";
char ring_chars[] = " .:-~*";

float rotation_x = 0, rotation_y = 0, rotation_z = 0;
int show_rings = 1;

void restore_terminal() {
    printf("\033[?25h"); // Show cursor
    printf("\033[2J");   // Clear screen
    printf("\033[H");    // Move cursor to home
}

void setup_terminal() {
    printf("\033[?25l"); // Hide cursor
    printf("\033[2J");   // Clear screen
}

void signal_handler(int sig) {
    restore_terminal();
    exit(0);
}

Point3D rotate_point(Point3D p, float rx, float ry, float rz) {
    Point3D result = p;
    
    // Rotate around X axis
    float y1 = result.y * cos(rx) - result.z * sin(rx);
    float z1 = result.y * sin(rx) + result.z * cos(rx);
    result.y = y1;
    result.z = z1;
    
    // Rotate around Y axis
    float x2 = result.x * cos(ry) + result.z * sin(ry);
    float z2 = -result.x * sin(ry) + result.z * cos(ry);
    result.x = x2;
    result.z = z2;
    
    // Rotate around Z axis
    float x3 = result.x * cos(rz) - result.y * sin(rz);
    float y3 = result.x * sin(rz) + result.y * cos(rz);
    result.x = x3;
    result.y = y3;
    
    return result;
}

// Check if a point is in shadow cast by the planet
int is_in_shadow(Point3D p, Point3D light_dir) {
    // Ray from point towards light
    Point3D ray_dir = {-light_dir.x, -light_dir.y, -light_dir.z};
    
    // Check intersection with planet sphere (origin at 0,0,0)
    float a = ray_dir.x * ray_dir.x + ray_dir.y * ray_dir.y + ray_dir.z * ray_dir.z;
    float b = 2 * (p.x * ray_dir.x + p.y * ray_dir.y + p.z * ray_dir.z);
    float c = p.x * p.x + p.y * p.y + p.z * p.z - PLANET_RADIUS * PLANET_RADIUS;
    
    float discriminant = b * b - 4 * a * c;
    
    if (discriminant < 0) return 0; // No intersection
    
    float t1 = (-b - sqrt(discriminant)) / (2 * a);
    float t2 = (-b + sqrt(discriminant)) / (2 * a);
    
    // If intersection is behind the point (t > 0), it's in shadow
    return (t1 > 0.01 || t2 > 0.01);
}

void draw_frame() {
    char screen[HEIGHT][WIDTH];
    float depth[HEIGHT][WIDTH];
    int is_ring_pixel[HEIGHT][WIDTH];
    
    // Initialize screen
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            screen[y][x] = ' ';
            depth[y][x] = -1000;
            is_ring_pixel[y][x] = 0;
        }
    }
    
    int center_x = WIDTH / 2;
    int center_y = HEIGHT / 2;
    Point3D light_dir = {0.7, 0.5, 1.0}; // Light direction
    
    // Normalize light direction
    float light_mag = sqrt(light_dir.x * light_dir.x + light_dir.y * light_dir.y + light_dir.z * light_dir.z);
    light_dir.x /= light_mag;
    light_dir.y /= light_mag;
    light_dir.z /= light_mag;
    
    // Draw planet
    for (int phi_i = 0; phi_i < 50; phi_i++) {
        for (int theta_i = 0; theta_i < 100; theta_i++) {
            float phi = (phi_i * PI) / 50;
            float theta = (theta_i * 2 * PI) / 100;
            
            Point3D p;
            p.x = PLANET_RADIUS * sin(phi) * cos(theta);
            p.y = PLANET_RADIUS * sin(phi) * sin(theta);
            p.z = PLANET_RADIUS * cos(phi);
            
            p = rotate_point(p, rotation_x, rotation_y, rotation_z);
            
            if (p.z > -50) {
                float perspective = 60 / (60 + p.z);
                int screen_x = (int)(center_x + p.x * perspective);
                int screen_y = (int)(center_y + p.y * perspective * 0.5);

                // int screen_x = (int)(center_x + p.x);
                // int screen_y = (int)(center_y + p.y / 2);
                
                if (screen_x >= 0 && screen_x < WIDTH && 
                    screen_y >= 0 && screen_y < HEIGHT) {
                    
                    if (p.z > depth[screen_y][screen_x]) {
                        depth[screen_y][screen_x] = p.z;
                        
                        // Calculate lighting with surface normal
                        Point3D normal = {p.x/PLANET_RADIUS, p.y/PLANET_RADIUS, p.z/PLANET_RADIUS};
                        float intensity = (normal.x * light_dir.x + normal.y * light_dir.y + normal.z * light_dir.z);
                        
                        // Ensure we don't go negative
                        if (intensity < 0) intensity = 0;
                        intensity = pow(intensity, 1.5);

                        int char_index = (int)(intensity * (sizeof(density_chars) - 2));
                        if (char_index < 0) char_index = 0;
                        if (char_index >= sizeof(density_chars) - 1) char_index = sizeof(density_chars) - 2;
                        
                        screen[screen_y][screen_x] = density_chars[char_index];
                    }
                }
            }
        }
    }
    
    // Draw rings if enabled
    if (show_rings) {
        for (int r = RING_INNER; r <= RING_OUTER; r++) {
            for (int theta_i = 0; theta_i < 200; theta_i++) {
                float theta = (theta_i * 2 * PI) / 200;
                
                Point3D p;
                p.x = r * cos(theta);
                p.y = 0;
                p.z = r * sin(theta);
                
                p = rotate_point(p, rotation_x, rotation_y, rotation_z);
                
                if (p.z > -50) {
                    int screen_x = (int)(center_x + p.x);
                    int screen_y = (int)(center_y + p.y / 2);
                    
                    if (screen_x >= 0 && screen_x < WIDTH && 
                        screen_y >= 0 && screen_y < HEIGHT) {
                        
                        if (p.z > depth[screen_y][screen_x] + 0.1) {
                            // Check if ring particle is in planet's shadow
                            float intensity = 1.0;
                            if (is_in_shadow(p, light_dir)) {
                                intensity = 0.2; // Dark shadow
                            } else {
                                // Ring lighting based on distance from planet and light angle
                                intensity = 0.3 + 0.7 * (1.0 - ((r - RING_INNER) / (float)(RING_OUTER - RING_INNER)));
                            }
                            
                            int char_index = (int)(intensity * (sizeof(ring_chars) - 2));
                            if (char_index < 0) char_index = 0;
                            if (char_index >= sizeof(ring_chars) - 1) char_index = sizeof(ring_chars) - 2;
                            
                            screen[screen_y][screen_x] = ring_chars[char_index];
                            depth[screen_y][screen_x] = p.z;
                            is_ring_pixel[screen_y][screen_x] = 1;
                        }
                    }
                }
            }
        }
    }
    
    // Render screen
    printf("\033[H"); // Move cursor to home
    
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            printf("%c", screen[y][x]);
        }
        printf("\n");
    }
}

int main() {
    setup_terminal();
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    atexit(restore_terminal);
    
    while (1) {
        draw_frame();
        
        rotation_x += 0.02;
        rotation_y += 0.03;
        rotation_z += 0.01;
        
        usleep(50000); // 50ms delay for smooth animation
    }
    
    return 0;
}
