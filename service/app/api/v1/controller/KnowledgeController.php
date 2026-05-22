<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\ChatRecord;
use app\model\KnowledgeBase;
use support\Request;
use support\Response;

/**
 * 智能问答
 * @Apidoc\Group("extensions")
 * @Apidoc\Sort(4)
 */
class KnowledgeController extends BaseController
{
    /**
     * 智能问答
     * POST /service/chat/ask
     */
    public function ask(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $question = trim($request->input('question', ''));

        if (empty($question)) {
            return $this->fail('请输入问题', 422);
        }

        // 关键词匹配搜索知识库（启用状态的文章）
        $articles = KnowledgeBase::where('status', 1)
            ->where('category_id', '>', 0)
            ->get();

        $matchedKb   = null;
        $matchedKbId = 0;
        $matchType   = 2; // 默认转人工
        $answer      = '';

        // 按关键词匹配
        foreach ($articles as $article) {
            $keywords = explode(',', $article->keywords);
            foreach ($keywords as $kw) {
                $kw = trim($kw);
                if (!empty($kw) && mb_strpos($question, $kw) !== false) {
                    $matchedKb   = $article;
                    $matchedKbId = $article->id;
                    $matchType   = 0; // 关键词匹配
                    $answer      = $article->answer;
                    break 2;
                }
            }
        }

        // 如果关键词未匹配到，尝试模糊匹配问题
        if (!$matchedKb) {
            foreach ($articles as $article) {
                if (mb_strpos($question, mb_substr($article->question, 0, 10)) !== false
                    || mb_strpos($article->question, mb_substr($question, 0, 10)) !== false) {
                    $matchedKb   = $article;
                    $matchedKbId = $article->id;
                    $matchType   = 0;
                    $answer      = $article->answer;
                    break;
                }
            }
        }

        // 记录对话
        $chatData = [
            'id'            => $this->generateId(),
            'user_id'       => $ownerId,
            'user_type'     => 1,
            'question'      => $question,
            'answer'        => $answer ?: '抱歉，我暂时无法回答您的问题，已转交人工客服处理，请稍候。',
            'match_type'    => $matchType,
            'matched_kb_id' => $matchedKbId,
            'is_helpful'    => 0,
        ];

        ChatRecord::create($chatData);

        if (!$matchedKb) {
            return $this->success([
                'answer'        => '抱歉，我暂时无法回答您的问题，已转交人工客服处理，请稍候。',
                'match_type'    => 2,
                'matched_kb_id' => 0,
            ]);
        }

        // 更新查看次数
        $matchedKb->increment('view_count');

        return $this->success([
            'answer'        => $answer,
            'match_type'    => 0,
            'matched_kb_id' => $this->encodeId($matchedKbId),
        ]);
    }
}
