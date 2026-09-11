export interface LoginRequest {
  email: string;
  password: string;
}

export interface MensajeResponse {
  mensaje: string;
}

export interface Sesion {
  nombre: string;
  email: string;
  rol: string;
  expiresIn: number;
}