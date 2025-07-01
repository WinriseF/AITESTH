import storage from '@ohos.data.storage';
import { BusinessError } from '@ohos.base';
import { common } from '@kit.AbilityKit';

const TOKEN_KEY = 'jwt_token';
let instance: AppDataSource | null = null;

export class AppDataSource {
  private appStorage: storage.Storage;
  private static readonly STORAGE_NAME = 'app_storage';

  private constructor(context: Context) {
    this.appStorage = storage.getStorageSync(context.filesDir + `/${AppDataSource.STORAGE_NAME}`);
  }

  // getInstance 的参数类型使用导入的 Context
  static getInstance(context?: Context): AppDataSource {
    if (instance === null) {
      if (!context) {
        throw new Error('必须通过有效Context初始化存储实例');
      }
      instance = new AppDataSource(context);
    }
    return instance;
  }

  // 其他数据操作方法保持异步
  async setToken(token: string): Promise<void> {
    try {
      await this.appStorage.put(TOKEN_KEY, token);
      await this.appStorage.flush();
    } catch (err) {
      const e = err as BusinessError;
      console.error(`存储Token失败[code:${e.code}, msg:${e.message}]`);
      throw new Error('Token存储异常');
    }
  }

  async getToken(): Promise<string> {
    try {
      // get方法本身就是异步的，所以这里使用 await 是正确的
      const token = await this.appStorage.get(TOKEN_KEY, '');
      return token as string;
    } catch (err) {
      console.warn('未找到有效Token，返回空');
      return '';
    }
  }

  async clearToken(): Promise<void> {
    try {
      await this.appStorage.delete(TOKEN_KEY);
      await this.appStorage.flush();
    } catch (err) {
      console.error('清除Token失败', JSON.stringify(err));
    }
  }
}