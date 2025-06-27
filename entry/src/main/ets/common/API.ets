import { QuestionModel } from "../model/QuestionModel";
import { getNormal, postNormal } from "../utls/HttpClient";
import { Result } from "../model/Result"; // 假设您会将 Result 定义在一个单独的模型文件中

export class GenerateQuestionDto {
  question?: string;
  questionNum?: number;
  questionFormat?: string;
  generateId?: string;
}

/**
 * 异步生成问题
 * @param generateQuestionDto 包含生成问题所需信息的DTO
 * @returns 返回一个包含生成ID的Result对象
 */
export const asyncGenerateQuestion = (generateQuestionDto: GenerateQuestionDto) =>
postNormal<Result<string>>(
  "/question/asyncGenerateQuestion",
  generateQuestionDto
);

/**
 * 根据生成ID查询问题
 * @param generateId 问题的生成ID
 * @returns 返回一个包含问题列表的Result对象
 */
export const selectQuestionByGenerateId = (generateId: string) =>
getNormal<Result<QuestionModel[]>>("/question/question/" + generateId);