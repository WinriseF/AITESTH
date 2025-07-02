import http from '@ohos.net.http';
import { BusinessError } from '@ohos.base';
import { AppDataSource } from '../common/AppDataSource';
import router from '@ohos.router'; // 引入router用于认证失败跳转

const API_BASE_URL = 'http://172.27.33.124:8080'; // 后端地址

/**
 * 定义通用的API响应结构，与后端保持一致
 */
export interface ApiResponse<T> {
  code: number;
  message: string;
  data: T;
}

/**
 * HttpClient 类，采用单例模式
 * 负责应用内所有的网络请求发送、认证处理和统一的响应处理
 */
class HttpClient {
  private static instance: HttpClient | null = null;

  // 私有化构造函数，确保无法通过 new 创建实例
  private constructor() {}

  /**
   * 获取 HttpClient 的唯一实例
   * @returns {HttpClient} HttpClient的单例对象
   */
  public static getInstance(): HttpClient {
    if (HttpClient.instance === null) {
      HttpClient.instance = new HttpClient();
    }
    return HttpClient.instance;
  }

  /**
   * 核心请求方法，所有GET/POST请求都将调用此方法
   * @param path API的相对路径
   * @param options http请求的配置
   * @private
   */
  private async request<T>(path: string, options: http.HttpRequestOptions): Promise<ApiResponse<T>> {
    const url = `${API_BASE_URL}${path}`;
    let httpRequest = http.createHttp();

    const headers: Record<string, string | number> = {
      'Content-Type': 'application/json',
    };

    if (options.header) {
      const headerKeys = Object.keys(options.header);
      for (const key of headerKeys) {
        headers[key] = options.header[key];
      }
    }

    // 自动附加JWT Token
    const token = await AppDataSource.getInstance().getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    options.header = headers;

    try {
      console.log(`[HttpClient] >>> ${options.method} ${url}`);
      const response = await httpRequest.request(url, options);

      console.log(`[HttpClient] <<< ${response.responseCode} ${url}`);

      // 处理HTTP响应
      if (response.responseCode >= 200 && response.responseCode < 300) {
        const resultJson = JSON.parse(response.result as string) as ApiResponse<T>;
        // 检查业务状态码
        if (resultJson.code === 200) {
          return resultJson;
        } else {
          // 业务失败，抛出后端提供的错误信息
          throw new Error(resultJson.message || '后端业务处理失败');
        }
      } else if (response.responseCode === 401 || response.responseCode === 403) {
        // 认证失败或权限不足
        console.error(`[HttpClient] 认证失败(${response.responseCode})，将清除Token并跳转到登录页。`);
        AppDataSource.getInstance().clearToken();
        router.replaceUrl({ url: 'pages/LoginPage' });
        throw new Error('认证失效，请重新登录');
      } else {
        // 其他HTTP错误
        throw new Error(`HTTP错误，状态码: ${response.responseCode}`);
      }
    } catch (err) {
      const error = err as BusinessError | Error;
      console.error(`[HttpClient] 请求 ${url} 发生严重错误:`, error.message);
      // 将所有错误统一向上抛出，由调用方(UI层)的catch块处理
      throw new Error(error.message || '未知网络错误');
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 封装通用的GET请求方法
   * @param path API的相对路径
   * @returns {Promise<ApiResponse<T>>}
   */
  public get<T>(path: string): Promise<ApiResponse<T>> {
    return this.request<T>(path, {
      method: http.RequestMethod.GET,
      connectTimeout: 15000,
      readTimeout: 15000,
    });
  }

  /**
   * 封装通用的POST请求方法
   * @param path API的相对路径
   * @param data 要发送的JS对象，会自动转换为JSON字符串
   * @returns {Promise<ApiResponse<T>>}
   */
  public post<T>(path: string, data: object): Promise<ApiResponse<T>> {
    return this.request<T>(path, {
      method: http.RequestMethod.POST,
      extraData: JSON.stringify(data),
      connectTimeout: 15000,
      readTimeout: 15000,
    });
  }

  // --- 其余方法 ---
  /**
   * 用于处理直接返回原始文本（如字符串）的POST请求
   * @param path API的相对路径
   * @param data 要发送的JS对象
   * @returns {Promise<string>} 直接返回响应的字符串内容
   */
  public async postAndGetRawResponse(path: string, data: object): Promise<string> {
    const url = `${API_BASE_URL}${path}`;
    let httpRequest = http.createHttp();

    const headers: Record<string, string | number> = { 'Content-Type': 'application/json' };
    const token = await AppDataSource.getInstance().getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    try {
      console.log(`[HttpClient] >>> POST(Raw) ${url}`);
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(data),
        connectTimeout: 60000, // 可以为长时任务设置更长的超时
        readTimeout: 120000,
      });

      console.log(`[HttpClient] <<< ${response.responseCode} ${url}`);

      if (response.responseCode === 200) {
        return response.result as string;
      } else {
        throw new Error(`HTTP 错误，状态码: ${response.responseCode}`);
      }
    } catch (err) {
      const error = err as BusinessError | Error;
      console.error(`[HttpClient] Raw请求 ${url} 发生严重错误:`, error.message);
      throw new Error(error.message || '未知网络错误');
    } finally {
      httpRequest.destroy();
    }
  }
}

// 默认导出的不是类本身，而是类的唯一实例
export default HttpClient.getInstance();