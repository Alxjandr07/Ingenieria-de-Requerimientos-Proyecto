import { HttpInterceptorFn } from '@angular/common/http';

/**
 * La autenticacion viaja en la cookie HttpOnly `access_token`
 * (Secure + SameSite=Strict). El interceptor solo asegura
 * `withCredentials` para que el navegador la envie.
 */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  return next(req.clone({ withCredentials: true }));
};
